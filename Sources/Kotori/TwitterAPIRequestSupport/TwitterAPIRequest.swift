import Foundation
import CryptoKit

public struct TwitterAPIRequest {
    let credential: RequiredCredential
    let resourceURL: URL
    let httpMethod: Kotori.HTTPMethod
    let parameters: [String: String]
    let nonce: UUID
    let timestamp: Date
    let uploadParameters: [String: Any]?

    struct RequiredCredential {
        let consumerKey: String
        let consumerSecret: String
        let oauthToken: String
        let oauthTokenSecret: String
    }

    init(credential: RequiredCredential, resourceURL: URL, httpMethod: Kotori.HTTPMethod, parameters: [String: String], nonce: UUID, timestamp: Date) {
        self.credential = credential
        self.resourceURL = resourceURL
        self.httpMethod = httpMethod
        self.parameters = parameters
        self.nonce = nonce
        self.timestamp = timestamp
        self.uploadParameters = nil
    }

    public init(resourceURL: URL,
                httpMethod: Kotori.HTTPMethod,
                parameters: [String: String],
                credential: TwitterCredential,
                clientCredential: ClientCredential) {
        self.credential = .init(consumerKey: clientCredential.consumerKey,
                                consumerSecret: clientCredential.consumerSecret,
                                oauthToken: credential.oauthToken,
                                oauthTokenSecret: credential.oauthTokenSecret)
        self.resourceURL = resourceURL
        self.httpMethod = httpMethod
        self.parameters = parameters
        self.nonce = UUID()
        self.timestamp = Date()
        self.uploadParameters = nil
    }

    public func makeURLRequest() -> URLRequest {
        var oauthParameters: [String: String] = [
            "oauth_consumer_key": credential.consumerKey,
            "oauth_nonce": nonce.uuidString,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(timestamp.timeIntervalSince1970),
            "oauth_version": "1.0",
            "oauth_token": credential.oauthToken
        ]

        var urlRequest: URLRequest
        let signature: String

        switch httpMethod {
        case .GET:
            guard var components = URLComponents(url: resourceURL, resolvingAgainstBaseURL: false) else { fatalError("Invalid resource url.") }
            components.queryItems = parameters.map({ URLQueryItem(name: $0, value: $1) })

            guard let url = components.url else { fatalError("Invalid parameters.") }
            urlRequest = .init(url: url)

            signature = try! OAuthSignature(
                httpMethod: httpMethod.rawValue,
                baseURL: resourceURL,
                oauthParameters: oauthParameters,
                parameters: parameters,
                credential: .init(
                    consumerSecret: credential.consumerSecret,
                    oauthTokenSecret: credential.oauthTokenSecret
                )
            ).calculate()

        case .POST:
            urlRequest = .init(url: resourceURL)
            urlRequest.httpBody = parameters.map({ (element) -> String in element.key + "=" + element.value.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)! })
                .joined(separator: "&")
                .data(using: .utf8)

            signature = try! OAuthSignature(
                httpMethod: httpMethod.rawValue,
                baseURL: resourceURL,
                oauthParameters: oauthParameters,
                parameters: parameters,
                credential: .init(
                    consumerSecret: credential.consumerSecret,
                    oauthTokenSecret: credential.oauthTokenSecret
                )
            ).calculate()
        }

        oauthParameters["oauth_signature"] = signature

        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.addValue(AuthorizationHeader(oauthParameters: oauthParameters).makeString(), forHTTPHeaderField: AuthorizationHeader.key)

        return urlRequest
    }
}

public struct TwitterMediaUploadRequest {
    struct RequiredCredential {
        let consumerKey: String
        let consumerSecret: String
        let oauthToken: String
        let oauthTokenSecret: String
    }

    let credential: RequiredCredential
    let resourceURL: URL
    let httpMethod: Kotori.HTTPMethod
    let nonce: UUID
    let timestamp: Date
    let parameters: [String: String]
    let data: Data

    public init(resourceURL: URL,
                httpMethod: Kotori.HTTPMethod,
                data: Data,
                parameters: [String: String],
                credential: TwitterCredential,
                clientCredential: ClientCredential) {
        self.credential = .init(consumerKey: clientCredential.consumerKey,
                                 consumerSecret: clientCredential.consumerSecret,
                                 oauthToken: credential.oauthToken,
                                 oauthTokenSecret: credential.oauthTokenSecret)
        self.resourceURL = resourceURL
        self.httpMethod = httpMethod
        self.nonce = UUID()
        self.timestamp = Date()
        self.parameters = parameters
        self.data = data
    }

    public func makeURLRequest() -> URLRequest {
        var oauthParameters: [String: String] = [
            "oauth_consumer_key": credential.consumerKey,
            "oauth_nonce": nonce.uuidString,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(timestamp.timeIntervalSince1970),
            "oauth_version": "1.0",
            "oauth_token": credential.oauthToken
        ]

        var urlRequest: URLRequest = .init(url: resourceURL)

        let boundary = "--" + UUID().uuidString

        let contentType = "multipart/form-data; boundary=\(boundary)"
        urlRequest.setValue(contentType, forHTTPHeaderField:"Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"media\"; \r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream \r\n\r\n".data(using: .utf8)!)
        body.append(data)

        parameters.forEach { (key, value) in
            body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)".data(using: .utf8)!)
        }

        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        urlRequest.httpBody = body

        let signature = try! OAuthSignature(
            httpMethod: httpMethod.rawValue,
            baseURL: resourceURL,
            oauthParameters: oauthParameters,
            parameters: [:],
            credential: .init(
                consumerSecret: credential.consumerSecret,
                oauthTokenSecret: credential.oauthTokenSecret
            )
        ).calculate()

        oauthParameters["oauth_signature"] = signature

        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.addValue(AuthorizationHeader(oauthParameters: oauthParameters).makeString(), forHTTPHeaderField: AuthorizationHeader.key)
        return urlRequest
    }
}
