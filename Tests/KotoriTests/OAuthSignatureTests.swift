import XCTest
@testable import Kotori

class OAuthSignatureTests: XCTestCase {

    typealias Subject = OAuthSignature

    override func setUpWithError() throws {
        let httpMethod = "POST"
        let baseURL = URL(string: "https://api.twitter.com/1.1/statuses/update.json")!
        let oauthParameters: [String: String] = [
            "oauth_consumer_key": "xvz1evFS4wEEPTGEFPHBog",
            "oauth_nonce": "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": "1318622958",
            "oauth_token": "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
            "oauth_version": "1.0"
        ]

        subject = try! Subject(httpMethod: httpMethod,
                               baseURL: baseURL,
                               oauthParameters: oauthParameters,
                               parameters: ["include_entities": "true", "status": "Hello Ladies + Gentlemen, a signed OAuth request!"],
                               credential: .init(consumerSecret: CredentialFixture.consumerSecret, oauthTokenSecret: CredentialFixture.tokenRequestResponse.oauthTokenSecret)
        )
    }

    private var subject: Subject!

    func test_makeParametersString() {
        XCTAssertEqual(subject.makeParametersString(), "include_entities=true&oauth_consumer_key=xvz1evFS4wEEPTGEFPHBog&oauth_nonce=kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1318622958&oauth_token=370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb&oauth_version=1.0&status=Hello%20Ladies%20%2B%20Gentlemen%2C%20a%20signed%20OAuth%20request%21")
    }

    func test_makeSignatreBaseString() {
        XCTAssertEqual(subject.makeSignatureBaseString(), "POST&https%3A%2F%2Fapi.twitter.com%2F1.1%2Fstatuses%2Fupdate.json&include_entities%3Dtrue%26oauth_consumer_key%3Dxvz1evFS4wEEPTGEFPHBog%26oauth_nonce%3DkYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1318622958%26oauth_token%3D370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb%26oauth_version%3D1.0%26status%3DHello%2520Ladies%2520%252B%2520Gentlemen%252C%2520a%2520signed%2520OAuth%2520request%2521")
    }

    func test_makeSignKey() {
        XCTAssertEqual(subject.makeSignKey(), "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw&PbKfYqSryyeKDWz4ebtY3o5ogNLG11WJuZBc9fQrQo")
    }

    func test_calculateSignature() {
        XCTAssertEqual(subject.calculate(), "mIN3nXSuA/u41YrVEZlYxu4TftY=")
    }
}
