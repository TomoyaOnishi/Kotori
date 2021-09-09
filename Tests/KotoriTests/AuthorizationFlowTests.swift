import Foundation
import XCTest

@testable import Kotori

class AuthorizationFlowTests: XCTestCase {

    typealias Subject = AuthorizationFlow

    func test_requestToken() {
        let components = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "Asia/Tokyo"), year: 2020, month: 10, day: 1)
        let timestamp = components.date!
        let nonce = UUID(uuidString: "0721E933-2B55-47B9-9308-E711913A9719")!
        let subject = Subject.TemporaryCredentialRequest(
            timestamp: timestamp,
            nonce: nonce,
            requiredCredential: .init(consumerKey: CredentialFixture.consumerKey,
                                      consumerSecret: CredentialFixture.consumerSecret,
                                      callbackURL: CredentialFixture.callbackURL)
        )

        let parameters = subject.parameters

        XCTAssertEqual(
            subject.requestURL,
            URL(string: "https://api.twitter.com/oauth/request_token")
        )

        XCTAssertEqual(
            subject.httpMethod,
            "POST"
        )

        XCTAssertEqual(
            parameters,
            [
                "oauth_consumer_key": "xvz1evFS4wEEPTGEFPHBog",
                "oauth_nonce": nonce.uuidString,
                "oauth_signature_method": "HMAC-SHA1",
                "oauth_timestamp": String(timestamp.timeIntervalSince1970),
                "oauth_version": "1.0",
                "oauth_callback": "https://yourWhitelistedCallbackUrl.com",
                "oauth_signature": "y9mWu/dpXPTechCJtXV6eI5p53U="
            ]
        )
    }

    func test_authorize() {
        let timestamp = Date()
        let nonce = UUID()

        let subject = Subject.ResourceOwnerAuthorization(
            timestamp: timestamp,
            nonce: nonce,
            requiredCredential: .init(
                oauthToken: CredentialFixture.temporaryCredentialRequestResponse.oauthToken
            )
        )

        XCTAssertEqual(
            subject.openURL,
            URL(string: "https://api.twitter.com/oauth/authorize?oauth_token=NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0")
        )
    }

    func test_accessToken() {
        let components = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "Asia/Tokyo"), year: 2020, month: 10, day: 1)
        let timestamp = components.date!
        let nonce = UUID(uuidString: "0721E933-2B55-47B9-9308-E711913A9719")!

        let subject = Subject.TokenRequest(
            timestamp: timestamp, nonce: nonce,
            requiredCredential: .init(
                consumerKey: CredentialFixture.consumerKey,
                consumerSecret: CredentialFixture.consumerSecret,
                oauthToken: CredentialFixture.resourceOwnerAuthorizationResponse.oauthToken,
                oauthVerifier: CredentialFixture.resourceOwnerAuthorizationResponse.oauthVerifier
            )
        )

        let parameters = subject.parameters

        XCTAssertEqual(
            subject.requestURL,
            URL(string: "https://api.twitter.com/oauth/access_token?oauth_token=NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0&oauth_verifier=uw7NjWHT6OJ1MpJOXsHfNxoAhPKpgI8BlYDhxEjIBY")
        )

        XCTAssertEqual(
            subject.httpMethod,
            "POST"
        )

        XCTAssertEqual(
            parameters,
            [
                "oauth_consumer_key": "xvz1evFS4wEEPTGEFPHBog",
                "oauth_nonce": nonce.uuidString,
                "oauth_signature_method": "HMAC-SHA1",
                "oauth_timestamp": String(timestamp.timeIntervalSince1970),
                "oauth_version": "1.0",
                "oauth_token": "NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0",
                "oauth_verifier": "uw7NjWHT6OJ1MpJOXsHfNxoAhPKpgI8BlYDhxEjIBY",
                "oauth_signature": "UKb7nM29+K2rgmC6vQZBDbPhn4c="
            ]
        )

        XCTContext.runActivity(named: "パラメータはURLパラメータを含んでいること") { _ in
            let timestamp = Date()
            let nonce = UUID()

            let subject = Subject.TokenRequest(
                timestamp: timestamp, nonce: nonce,
                requiredCredential: .init(
                    consumerKey: CredentialFixture.consumerKey,
                    consumerSecret: CredentialFixture.consumerSecret,
                    oauthToken: CredentialFixture.resourceOwnerAuthorizationResponse.oauthToken,
                    oauthVerifier: CredentialFixture.resourceOwnerAuthorizationResponse.oauthVerifier
                )
            )

            let parameters = subject.parameters

            URLComponents(url: subject.requestURL, resolvingAgainstBaseURL: false)?.queryItems?.forEach({ (item) in
                XCTAssertEqual(parameters[item.name], item.value)
            })
        }
    }
}

