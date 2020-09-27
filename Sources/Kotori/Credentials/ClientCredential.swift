import Foundation

public struct ClientCredential {
    public init(consumerKey: String, consumerSecret: String, callbackURL: URL) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.callbackURL = callbackURL
    }

    let consumerKey: String
    let consumerSecret: String
    let callbackURL: URL
}
