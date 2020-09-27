import Foundation

public struct TokenCredential: Codable, Equatable, Hashable {
    public let oauthToken: String
    public let oauthTokenSecret: String
    public let userID: UserID
    public let screenName: String

    public init(oauthToken: String, oauthTokenSecret: String, userID: UserID, screenName: String) {
        self.oauthToken = oauthToken
        self.oauthTokenSecret = oauthTokenSecret
        self.userID = userID
        self.screenName = screenName
    }
}

public struct UserID: Codable, Equatable, Hashable {
    public let value: Int64

    public init(_ rawValue: Int64) {
        self.value = rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Int64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
