import Foundation

struct TemporaryCredential: Decodable {
    let oauthToken: String
    let oauthTokenSecret: String
    let oauthVerifier: String
}
