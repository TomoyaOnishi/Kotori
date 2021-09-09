import Foundation

public struct MediaID: Codable {
    public let value: UInt64
    public init(from decoder: Decoder) throws {
        self.value = try decoder.singleValueContainer().decode(UInt64.self)
    }
}

struct InitCommand {
    let command: String = "INIT"
    let totalBytes: Int
    let mediaType: String
    let httpMethod: Kotori.HTTPMethod = .POST

    var parameters: [String: String] {
        [
            "command": command,
            "total_bytes": String(totalBytes),
            "media_type": "image/png"
        ]
    }

    struct Response: Decodable {
        let mediaID: MediaID

        enum CodingKeys: String, CodingKey {
            case mediaID = "media_id"
        }
    }
}

struct AppendCommand {
    let command: String = "APPEND"
    let mediaID: MediaID
    let media: Data
    let segmentIndex: Int
    let httpMethod: Kotori.HTTPMethod = .POST

    var parameters: [String: String] {
        [
            "command": command,
            "media_id": String(mediaID.value),
            "segment_index": String(segmentIndex),
        ]
    }
}

struct FinilizeCommand {
    let command: String = "FINALIZE"
    let mediaID: MediaID
    let httpMethod: Kotori.HTTPMethod = .POST

    var parameters: [String: String] {
        [
            "command": command,
            "media_id": String(mediaID.value),
        ]
    }

    struct Response: Decodable {
        let mediaID: MediaID
        let processingInfo: ProcessingInfo?

        enum CodingKeys: String, CodingKey {
            case mediaID = "media_id"
            case processingInfo = "processing_info"
        }
    }
}

struct StatusCommand {
    let command: String = "STATUS"
    let mediaID: MediaID
    let httpMethod: Kotori.HTTPMethod = .GET

    var parameters: [String: String] {
        [
            "command": command,
            "media_id": String(mediaID.value),
        ]
    }

    struct Response: Decodable {
        let mediaID: MediaID
        let processingInfo: ProcessingInfo?

        enum CodingKeys: String, CodingKey {
            case mediaID = "media_id"
            case processingInfo = "processing_info"
        }
    }
}

struct ProcessingInfo: Decodable {
    let state: State
    let checkAfter: UInt64?

    enum CodingKeys: String, CodingKey {
        case state = "state"
        case checkAfter = "check_after_secs"
    }

    enum State: String, Decodable {
        case pending = "pending"
        case inProgress = "in_progress"
        case failed = "failed"
        case succeeded = "succeeded"
    }
}

public struct MediaUploadOutput {
    public let mediaID: MediaID
    public let index: Int
}

public class TwitterMediaUploader {

    public typealias Output = MediaUploadOutput
    public typealias Failure = MediaUploadError

    private static let chunkedUploadSizeInMB: Int = 1

    let credential: TwitterCredential
    let resourceURL: URL = URL(string: "https://upload.twitter.com/1.1/media/upload.json")!
    let data: Data
    let mimeType: String
    let clientCredential: ClientCredential
    let index: Int
    public init(credential: TwitterCredential, data: Data, mimeType: String, clientCredential: ClientCredential, index: Int) {
        self.credential = credential
        self.data = data
        self.mimeType = mimeType
        self.clientCredential = clientCredential
        self.index = index
    }

    public func upload() async throws -> Output {
        let initResponse = try await initCommand()
        let isAppendSuccess = try await appendCommand(initResponse: initResponse)
        guard isAppendSuccess else { throw TwitterMediaUploader.MediaUploadError.appendFailed }
        let mediaUploadOutput = try await finilizeCommand(initResponse: initResponse)
        return mediaUploadOutput
    }

    private func initCommand() async throws -> InitCommand.Response {
        let initCommad = InitCommand(totalBytes: data.count, mediaType: mimeType)
        let initTwitterRequest = TwitterAPIRequest(resourceURL: self.resourceURL,
                                                   httpMethod: initCommad.httpMethod,
                                                   parameters: initCommad.parameters,
                                                   credential: self.credential,
                                                   clientCredential: self.clientCredential)

        let (data, _) = try await URLSession.shared.data(for: initTwitterRequest.makeURLRequest())
        return try JSONDecoder().decode(InitCommand.Response.self, from: data)
    }

    private func appendCommand(initResponse: InitCommand.Response) async throws -> Bool {
        let sizeInMB: Float = Float(self.data.count) / 1024.0 / 1024.0
        let preffredChunkCount: Int = Int(ceil(Float(ceil(sizeInMB)) / Float(Self.chunkedUploadSizeInMB)))

        var uploadData = data

        let appendRequests: [URLRequest] = (0..<preffredChunkCount).map { index in
            let chunkSize = Self.chunkedUploadSizeInMB * 1024 * 1024
            let chunk: Data
            if chunkSize < uploadData.count {
                chunk = uploadData.prefix(chunkSize)
                uploadData.removeFirst(chunkSize)
            } else {
                chunk = uploadData
            }

            let appendCommand = AppendCommand(mediaID: initResponse.mediaID, media: chunk, segmentIndex: index)
            let appendTwitterRequest = TwitterMediaUploadRequest(resourceURL: self.resourceURL,
                                                                 httpMethod: appendCommand.httpMethod,
                                                                 data: appendCommand.media,
                                                                 parameters: appendCommand.parameters,
                                                                 credential: self.credential,
                                                                 clientCredential: self.clientCredential)
            return appendTwitterRequest.makeURLRequest()
        }

        let isAppendSuccess = try await withThrowingTaskGroup(of: HTTPURLResponse.self, body: { group -> Bool in
            for appendRequest in appendRequests {
                group.addTask(priority: .userInitiated) {
                    let (_, response) = try await URLSession.shared.data(for: appendRequest)
                    return response as! HTTPURLResponse
                }
            }

            let isAllSuccess = try await group.allSatisfy { $0.statusCode == 204 }
            return isAllSuccess
        })

        return isAppendSuccess
    }

    private func finilizeCommand(initResponse: InitCommand.Response) async throws -> MediaUploadOutput {
        let finalizeCommand = FinilizeCommand(mediaID: initResponse.mediaID)
        let finalizeTwitterRequest = TwitterAPIRequest(resourceURL: self.resourceURL,
                                                       httpMethod: finalizeCommand.httpMethod,
                                                       parameters: finalizeCommand.parameters,
                                                       credential: self.credential,
                                                       clientCredential: self.clientCredential)

        let (data, _) = try await URLSession.shared.data(for: finalizeTwitterRequest.makeURLRequest())
        let finilizeResponse = try JSONDecoder().decode(FinilizeCommand.Response.self, from: data)

        guard let processingInfo = finilizeResponse.processingInfo else {
            return MediaUploadOutput(mediaID: finilizeResponse.mediaID, index: index)
        }

        let delay: UInt64 = processingInfo.checkAfter ?? 5
        await Task.sleep(delay)

        let statusCommand = StatusCommand(mediaID: initResponse.mediaID)
        let statusTwitterRequest = TwitterAPIRequest(resourceURL: self.resourceURL,
                                                     httpMethod: statusCommand.httpMethod,
                                                     parameters: statusCommand.parameters,
                                                     credential: self.credential,
                                                     clientCredential: self.clientCredential)

        let (statusData, _) = try await URLSession.shared.data(for: statusTwitterRequest.makeURLRequest())
        let statusResponse = try JSONDecoder().decode(StatusCommand.Response.self, from: statusData)

        guard statusResponse.processingInfo?.state == .succeeded else {
            throw TwitterMediaUploader.MediaUploadError.giveup(recoveryHint: "The developer gives up. Please PRs for the error handling.")
        }

        return MediaUploadOutput(mediaID: statusResponse.mediaID, index: index)
    }
}
