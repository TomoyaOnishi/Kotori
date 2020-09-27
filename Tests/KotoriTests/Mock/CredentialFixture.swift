import Foundation
@testable import Kotori

struct CredentialFixture {
    static let consumerKey: String = "xvz1evFS4wEEPTGEFPHBog"
    static let consumerSecret: String = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
    static let callbackURL: URL = URL(string: "https://yourWhitelistedCallbackUrl.com")!
    
    static let temporaryCredentialRequestResponse: AuthorizationFlow.TemporaryCredentialRequest.Response = .init(
        oauthToken: "NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0",
        oauthTokenSecret: "veNRnAWe6inFuo8o2u8SLLZLjolYDmDP7SzL0YfYI",
        oauthCallbackConfirmed: "true"
    )
    static let resourceOwnerAuthorizationResponse: AuthorizationFlow.ResourceOwnerAuthorization.Response = .init(
        oauthToken: "NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0",
        oauthVerifier: "uw7NjWHT6OJ1MpJOXsHfNxoAhPKpgI8BlYDhxEjIBY"
    )
    static let tokenRequestResponse: AuthorizationFlow.TokenRequest.Response = .init(
        oauthToken: "7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4",
        oauthTokenSecret: "PbKfYqSryyeKDWz4ebtY3o5ogNLG11WJuZBc9fQrQo",
        userID: UserID(123),
        screenName: "Tomoya_Onishi"
    )
}
