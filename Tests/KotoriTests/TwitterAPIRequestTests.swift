import Foundation
import XCTest
@testable import Kotori

class TwitterAPIRequestTests: XCTestCase {
    typealias Subject = TwitterAPIRequest

    func test_authorize() {
        XCTContext.runActivity(named: "no url query, no http body.") { _ in
            let components = DateComponents(calendar: Calendar.current, year: 2020, month: 10, day: 1)
            let timestamp = components.date!
            let nonce = UUID(uuidString: "0721E933-2B55-47B9-9308-E711913A9719")!

            let subject = Subject(credential: .init(
                                    consumerKey: CredentialFixture.consumerKey,
                                    consumerSecret: CredentialFixture.consumerSecret,
                                    oauthToken: CredentialFixture.tokenRequestResponse.oauthToken,
                                    oauthTokenSecret: CredentialFixture.tokenRequestResponse.oauthTokenSecret),
                                  resourceURL: URL(string: "https://api.twitter.com/1.1/account/verify_credentials.json")!,
                                  httpMethod: .GET,
                                  parameters: [:],
                                  nonce: nonce,
                                  timestamp: timestamp
            )

            let request = subject.makeURLRequest()

            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, URL(string: "https://api.twitter.com/1.1/account/verify_credentials.json?"))
            XCTAssertEqual(request.allHTTPHeaderFields?[AuthorizationHeader.key], "OAuth oauth_consumer_key=\"xvz1evFS4wEEPTGEFPHBog\", oauth_nonce=\"0721E933-2B55-47B9-9308-E711913A9719\", oauth_signature=\"odRtlhOxlRLXS%2FDsRbi%2BV80HR8c%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1601478000.0\", oauth_token=\"7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4\", oauth_version=\"1.0\"")
        }

        XCTContext.runActivity(named: "no url query, no http body.") { _ in
            let components = DateComponents(calendar: Calendar.current, year: 2020, month: 10, day: 1)
            let timestamp = components.date!
            let nonce = UUID(uuidString: "0721E933-2B55-47B9-9308-E711913A9719")!

            let subject = Subject(credential: .init(
                                    consumerKey: CredentialFixture.consumerKey,
                                    consumerSecret: CredentialFixture.consumerSecret,
                                    oauthToken: CredentialFixture.tokenRequestResponse.oauthToken,
                                    oauthTokenSecret: CredentialFixture.tokenRequestResponse.oauthTokenSecret),
                                  resourceURL: URL(string: "https://api.twitter.com/1.1/users/show.json")!,
                                  httpMethod: .GET,
                                  parameters: ["screen_name": "Tomoya_Onishi"],
                                  nonce: nonce,
                                  timestamp: timestamp
            )

            let request = subject.makeURLRequest()

            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, URL(string: "https://api.twitter.com/1.1/users/show.json?screen_name=Tomoya_Onishi"))
            XCTAssertEqual(request.allHTTPHeaderFields?[AuthorizationHeader.key], "OAuth oauth_consumer_key=\"xvz1evFS4wEEPTGEFPHBog\", oauth_nonce=\"0721E933-2B55-47B9-9308-E711913A9719\", oauth_signature=\"pjdpAmz0LgfgEESmHSrIqnnl%2B0U%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1601478000.0\", oauth_token=\"7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4\", oauth_version=\"1.0\"")
        }

        XCTContext.runActivity(named: "url query, http body") { _ in
            let components = DateComponents(calendar: Calendar.current, year: 2020, month: 10, day: 1)
            let timestamp = components.date!
            let nonce = UUID(uuidString: "0721E933-2B55-47B9-9308-E711913A9719")!

            let subject = Subject(credential: .init(
                                    consumerKey: CredentialFixture.consumerKey,
                                    consumerSecret: CredentialFixture.consumerSecret,
                                    oauthToken: CredentialFixture.tokenRequestResponse.oauthToken,
                                    oauthTokenSecret: CredentialFixture.tokenRequestResponse.oauthTokenSecret),
                                  resourceURL: URL(string: "https://api.twitter.com/1.1/statuses/update.json")!,
                                  httpMethod: .POST,
                                  parameters: ["status": "Hello Ladies + Gentlemen, a signed OAuth request!"],
                                  nonce: nonce,
                                  timestamp: timestamp
            )

            let request = subject.makeURLRequest()

            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields?[AuthorizationHeader.key], "OAuth oauth_consumer_key=\"xvz1evFS4wEEPTGEFPHBog\", oauth_nonce=\"0721E933-2B55-47B9-9308-E711913A9719\", oauth_signature=\"7wvTJvJFBCaQDQLwKabYPGbpDOs%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1601478000.0\", oauth_token=\"7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4\", oauth_version=\"1.0\"")
            XCTAssertNotNil(request.url)
            XCTAssertEqual(request.url?.query, nil)
        }
    }
}
