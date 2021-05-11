import Foundation
import Combine
import Dispatch

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
    let checkAfter: TimeInterval?

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
    private var cancellers: Set<AnyCancellable> = .init()

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

    public func publisher() -> AnyPublisher<Output, Failure> {
        Future<Output, Failure>.init { [weak self] (promise) in
            guard let self = self else { return }

            /**
             Init command phase.
             */

            let initCommad = InitCommand(totalBytes: self.data.count, mediaType: self.mimeType)
            let twitterRequest = TwitterAPIRequest(resourceURL: self.resourceURL,
                                                   httpMethod: initCommad.httpMethod,
                                                   parameters: initCommad.parameters,
                                                   credential: self.credential,
                                                   clientCredential: self.clientCredential)

            URLSession.shared.dataTaskPublisher(for: twitterRequest.makeURLRequest())
                .map({ $0.data })
                .decode(type: InitCommand.Response.self, decoder: JSONDecoder())
                .sink(
                    receiveCompletion: { result in
                        switch result {
                        case .finished:
                            break
                        case .failure(let error):
                            promise(.failure(.initFailed(underlyingError: error)))
                        }
                    },
                    receiveValue: { initResponse in

                        /**
                         Append command phase.
                         */

                        let sizeInMB: Float = Float(self.data.count) / 1024.0 / 1024.0
                        let preffredChunkCount: Int = Int(ceil(Float(ceil(sizeInMB)) / Float(Self.chunkedUploadSizeInMB)))

                        var uploadData = self.data
                        let chunkedUploadTasks = (0..<preffredChunkCount).map({ index -> URLSession.DataTaskPublisher in
                            let chunkSize = Self.chunkedUploadSizeInMB * 1024 * 1024
                            let chunk: Data
                            if chunkSize < uploadData.count {
                                chunk = uploadData.prefix(chunkSize)
                                uploadData.removeFirst(chunkSize)
                            } else {
                                chunk = uploadData
                            }

                            let appendCommand = AppendCommand(mediaID: initResponse.mediaID, media: chunk, segmentIndex: index)
                            let twitterRequest = TwitterMediaUploadRequest(resourceURL: self.resourceURL,
                                                                           httpMethod: appendCommand.httpMethod,
                                                                           data: appendCommand.media,
                                                                           parameters: appendCommand.parameters,
                                                                           credential: self.credential,
                                                                           clientCredential: self.clientCredential)

                            return URLSession.shared.dataTaskPublisher(for: twitterRequest.makeURLRequest())
                        })

                        Publishers.MergeMany(chunkedUploadTasks)
                            .compactMap({ $0.response as? HTTPURLResponse })
                            .allSatisfy({ 200 ..< 300 ~= $0.statusCode })
                            .sink(
                                receiveCompletion: { result in
                                    switch result {
                                    case .finished:
                                        break
                                    case .failure(let error):
                                        promise(.failure(.appendFailed(underlyingError: error)))
                                    }
                                },
                                receiveValue: { (isAllSatisfy) in
                                    if isAllSatisfy {

                                        /**
                                         Finalize command phase.
                                         */

                                        let finalizeCommand = FinilizeCommand(mediaID: initResponse.mediaID)
                                        let twitterRequest = TwitterAPIRequest(resourceURL: self.resourceURL,
                                                                               httpMethod: finalizeCommand.httpMethod,
                                                                               parameters: finalizeCommand.parameters,
                                                                               credential: self.credential,
                                                                               clientCredential: self.clientCredential)

                                        URLSession.shared.dataTaskPublisher(for: twitterRequest.makeURLRequest())
                                            .map({ $0.data })
                                            .decode(type: FinilizeCommand.Response.self, decoder: JSONDecoder())
                                            .sink(
                                                receiveCompletion: { (result) in
                                                    switch result {
                                                    case .finished:
                                                        break
                                                    case .failure(let error):
                                                        promise(.failure(.finalizeFailed(underlyingError: error)))
                                                    }
                                                },
                                                receiveValue: { (finalizeResponse) in
                                                    if let processingInfo = finalizeResponse.processingInfo {

                                                        /**
                                                         Status check phase
                                                         */

                                                        let delay = processingInfo.checkAfter ?? 5
                                                        let statusCommand = StatusCommand(mediaID: initResponse.mediaID)
                                                        let twitterRequest = TwitterAPIRequest(resourceURL: self.resourceURL,
                                                                                               httpMethod: statusCommand.httpMethod,
                                                                                               parameters: statusCommand.parameters,
                                                                                               credential: self.credential,
                                                                                               clientCredential: self.clientCredential)

                                                        URLSession.shared.dataTaskPublisher(for: twitterRequest.makeURLRequest())
                                                            .delay(for: .seconds(delay), scheduler: OperationQueue.current!)
                                                            .map({ $0.data })
                                                            .decode(type: StatusCommand.Response.self, decoder: JSONDecoder())
                                                            .sink(
                                                                receiveCompletion: { result in
                                                                    switch result {
                                                                    case .finished:
                                                                        break
                                                                    case .failure(let error):
                                                                        promise(.failure(.giveup(underlyingError: error, recoveryHint: "Retry upload or fix me.")))
                                                                    }
                                                                },
                                                                receiveValue: { statusCommandResponse in
                                                                    if statusCommandResponse.processingInfo?.state == .succeeded {
                                                                        promise(.success(MediaUploadOutput(mediaID: statusCommandResponse.mediaID, index: self.index)))
                                                                    } else {
                                                                        promise(.failure(.giveup(underlyingError: nil, recoveryHint: "Retry upload or fix me.")))
                                                                    }
                                                                })
                                                            .store(in: &self.cancellers)
                                                    } else {
                                                        promise(.success(MediaUploadOutput(mediaID: finalizeResponse.mediaID, index: self.index)))
                                                    }
                                                })
                                            .store(in: &self.cancellers)
                                    }
                                })
                            .store(in: &self.cancellers)
                    })
                .store(in: &self.cancellers)
        }
        .eraseToAnyPublisher()
    }
}
