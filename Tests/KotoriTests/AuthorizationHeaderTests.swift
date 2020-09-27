import Foundation
import XCTest
@testable import Kotori

class AuthorizationHeaderTests: XCTestCase {

    typealias Subject = AuthorizationHeader

    private var subject: Subject!

    override func setUpWithError() throws {
        let parameters: [String: String] = [
            "oauth_consumer_key": "xvz1evFS4wEEPTGEFPHBog",
            "oauth_nonce": "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": "1318622958",
            "oauth_token": "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
            "oauth_version": "1.0",
            "oauth_signature": "tnnArxj06cWHq44gCs1OSKk/jLY="
        ]
        subject = .init(oauthParameters: parameters)
    }

    func test_makeHeaderString() {
        let result = subject.makeString()

        XCTAssertEqual(
            result,
            """
OAuth oauth_consumer_key="xvz1evFS4wEEPTGEFPHBog", oauth_nonce="kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg", oauth_signature="tnnArxj06cWHq44gCs1OSKk%2FjLY%3D", oauth_signature_method="HMAC-SHA1", oauth_timestamp="1318622958", oauth_token="370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb", oauth_version="1.0"
"""
        )

    }
}

