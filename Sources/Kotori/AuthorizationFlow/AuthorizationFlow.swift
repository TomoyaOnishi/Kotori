import Foundation

struct AuthorizationFlow {
    struct TemporaryCredentialRequest {
        let endpoint: URL = URL(string: "https://api.twitter.com/oauth/request_token")!
        let httpMethod: String = "POST"

        let timestamp: Date
        let nonce: UUID
        let requiredCredential: RequiredCredential

        struct RequiredCredential {
            let consumerKey: String
            let consumerSecret: String
            let oauthTokenSecret: String = ""
            let callbackURL: URL
        }

        init(timestamp: Date, nonce: UUID, requiredCredential: RequiredCredential) {
            self.timestamp = timestamp
            self.nonce = nonce
            self.requiredCredential = requiredCredential
        }

        var requestURL: URL {
            return endpoint
        }

        var parameters: [String: String] {
            var parameters = [
                "oauth_consumer_key": requiredCredential.consumerKey,
                "oauth_nonce": nonce.uuidString,
                "oauth_signature_method": "HMAC-SHA1",
                "oauth_timestamp": String(timestamp.timeIntervalSince1970),
                "oauth_version": "1.0",
                "oauth_callback": requiredCredential.callbackURL.absoluteString
            ]

            let signature = try! OAuthSignature(
                httpMethod: httpMethod,
                baseURL: endpoint,
                oauthParameters: parameters,
                parameters: [:],
                credential: .init(
                    consumerSecret: requiredCredential.consumerSecret,
                    oauthTokenSecret: requiredCredential.oauthTokenSecret
                )
            ).calculate()

            parameters["oauth_signature"] = signature

            return parameters
        }

        var urlRequest: URLRequest {
            var request: URLRequest = .init(url: requestURL)
            let authorizationHeader = AuthorizationHeader(oauthParameters: parameters).makeString()
            request.addValue(authorizationHeader, forHTTPHeaderField: AuthorizationHeader.key)
            request.httpMethod = httpMethod
            return request
        }

        struct Response {
            let oauthToken: String
            let oauthTokenSecret: String
            let oauthCallbackConfirmed: String

            init(_ responseData: Data) {
                guard let response = String(data: responseData, encoding: .utf8) else { fatalError() }

                let tokens = response.split(separator: "&").reduce([:]) { (result, string) -> [String: String] in
                    var next = result
                    let keyAndValue = string.split(separator: "=")
                    let key = String(keyAndValue[0])
                    let value = String(keyAndValue[1])
                    next[key] = value
                    return next
                }

                precondition(tokens["oauth_token"] != nil)
                precondition(tokens["oauth_token_secret"] != nil)
                precondition(tokens["oauth_callback_confirmed"] != nil)

                self.oauthToken = tokens["oauth_token"]!
                self.oauthTokenSecret = tokens["oauth_token_secret"]!
                self.oauthCallbackConfirmed = tokens["oauth_callback_confirmed"]!
            }

            init(oauthToken: String, oauthTokenSecret: String, oauthCallbackConfirmed: String) {
                self.oauthToken = oauthToken
                self.oauthTokenSecret = oauthTokenSecret
                self.oauthCallbackConfirmed = oauthCallbackConfirmed
            }
        }

    }

    struct ResourceOwnerAuthorization {
        let endpoint: URL = URL(string: "https://api.twitter.com")!
        let timestamp: Date
        let nonce: UUID
        let credential: RequiredCredential

        struct RequiredCredential {
            let oauthToken: String
        }

        public init(timestamp: Date, nonce: UUID, requiredCredential: RequiredCredential) {
            self.timestamp = timestamp
            self.nonce = nonce
            self.credential = requiredCredential
        }

        var openURL: URL {
            var components = URLComponents(url: URL(string: "oauth/authorize", relativeTo: endpoint)!, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                .init(name: "oauth_token", value: credential.oauthToken),
            ]
            return components.url!
        }

        struct Response {
            let oauthToken: String
            let oauthVerifier: String

            init(_ responseURL: URL) {
                guard let components = URLComponents(url: responseURL, resolvingAgainstBaseURL: false) else { fatalError() }
                guard let oauthToken = components.queryItems?.first(where: { $0.name == "oauth_token" })?.value,
                      let oauthVerifier = components.queryItems?.first(where: { $0.name == "oauth_verifier" })?.value else {
                    fatalError()
                }

                self.oauthToken = oauthToken
                self.oauthVerifier = oauthVerifier
            }

            init(oauthToken: String, oauthVerifier: String) {
                self.oauthToken = oauthToken
                self.oauthVerifier = oauthVerifier
            }
        }
    }

    struct TokenRequest {
        let endpoint: URL = URL(string: "https://api.twitter.com/oauth/access_token")!
        let httpMethod: String = "POST"

        let timestamp: Date
        let nonce: UUID
        let requiredCredential: RequiredCredential

        struct RequiredCredential {
            let consumerKey: String
            let consumerSecret: String
            let oauthToken: String
            let oauthVerifier: String
            let oauthTokenSecret: String = ""
        }

        public init(timestamp: Date, nonce: UUID, requiredCredential: RequiredCredential) {
            self.timestamp = timestamp
            self.nonce = nonce
            self.requiredCredential = requiredCredential
        }

        var requestURL: URL {
            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
            components.queryItems = [
                .init(name: "oauth_token", value: requiredCredential.oauthToken),
                .init(name: "oauth_verifier", value: requiredCredential.oauthVerifier)
            ]
            return components.url!
        }

        var parameters: [String: String] {
            var parameters = [
                "oauth_consumer_key": requiredCredential.consumerKey,
                "oauth_nonce": nonce.uuidString,
                "oauth_signature_method": "HMAC-SHA1",
                "oauth_timestamp": String(timestamp.timeIntervalSince1970),
                "oauth_version": "1.0",
                "oauth_token": requiredCredential.oauthToken,
                "oauth_verifier": requiredCredential.oauthVerifier
            ]

            let signature = try! OAuthSignature(
                httpMethod: httpMethod,
                baseURL: endpoint,
                oauthParameters: parameters,
                parameters: [:],
                credential: .init(
                    consumerSecret: requiredCredential.consumerSecret,
                    oauthTokenSecret: requiredCredential.oauthTokenSecret
                )
            ).calculate()

            parameters["oauth_signature"] = signature

            return parameters
        }

        var urlRequest: URLRequest {
            var request: URLRequest = .init(url: requestURL)
            let authorizationHeader = AuthorizationHeader(oauthParameters: parameters).makeString()
            request.addValue(authorizationHeader, forHTTPHeaderField: AuthorizationHeader.key)
            request.httpMethod = httpMethod
            return request
        }

        struct Response {
            public let oauthToken: String
            public let oauthTokenSecret: String
            public let userID: UserID
            public let screenName: String

            init(_ responseData: Data) {
                guard let response = String(data: responseData, encoding: .utf8) else { fatalError() }

                let tokens = response.split(separator: "&").reduce([:]) { (result, string) -> [String: String] in
                    var next = result
                    let keyAndValue = string.split(separator: "=")
                    let key = String(keyAndValue[0])
                    let value = String(keyAndValue[1])
                    next[key] = value
                    return next
                }

                precondition(tokens["oauth_token"] != nil)
                precondition(tokens["oauth_token_secret"] != nil)
                precondition(tokens["user_id"] != nil)
                precondition(tokens["screen_name"] != nil)

                self.oauthToken = tokens["oauth_token"]!
                self.oauthTokenSecret = tokens["oauth_token_secret"]!
                let userID = Int64(tokens["user_id"]!)!
                self.userID = UserID(userID)
                self.screenName = tokens["screen_name"]!
            }

            init(oauthToken: String, oauthTokenSecret: String, userID: UserID, screenName: String) {
                self.oauthToken = oauthToken
                self.oauthTokenSecret = oauthTokenSecret
                self.userID = userID
                self.screenName = screenName
            }
        }
    }
}
