import Foundation
import XCTest
import Security
@testable import Kotori

class KeychainServiceTests: XCTestCase {
    typealias Subject = KeychainService
    private var subject: Subject!

    func test_add() {
        var isCalled = false
        let credentials = TokenCredential(oauthToken: "", oauthTokenSecret: "", userID: .init(123), screenName: "")
        let data = try! JSONEncoder().encode(credentials)

        let expectedQuery: CFDictionary = [kSecClass as String: kSecClassGenericPassword,
                                           kSecAttrAccount as String: 123,
                                           kSecAttrAccessGroup as String: "accessGroupIdentifier",
                                           kSecValueData as String: data,
                                           kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary

        subject = Subject(itemAdd: { (query, _) -> OSStatus in
            isCalled = true
            XCTAssertEqual(query, expectedQuery)
            return errSecSuccess
        }, itemUpdate: { (_, _) -> OSStatus in
            fatalError()
        }, itemCopy: { (_, _) -> OSStatus in
            fatalError()
        }, itemDelete: { _ -> OSStatus in
            fatalError()
        }, accessGroup: "accessGroupIdentifier")

        subject.add(credentials)

        XCTAssertTrue(isCalled)
    }

    func test_update() {
        var isCalled = false
        let userID = UserID(123)
        let credentials = TokenCredential(oauthToken: "", oauthTokenSecret: "", userID: .init(123), screenName: "")
        let data = try! JSONEncoder().encode(credentials)

        let expectedQuery: CFDictionary = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: 123,
            kSecAttrAccessGroup as String: "accessGroupIdentifier",
        ] as CFDictionary

        let valueExpected: CFDictionary = [
            kSecValueData as String: data
        ] as CFDictionary

        subject = Subject(
            itemAdd: { (_, _) -> OSStatus in
                fatalError()
            },
            itemUpdate: { (query, value) -> OSStatus in
                isCalled = true
                XCTAssertEqual(query, expectedQuery)
                XCTAssertEqual(value, valueExpected)
                return errSecSuccess
            },
            itemCopy: { (_, _) -> OSStatus in
                fatalError()
            },
            itemDelete: { (_) -> OSStatus in
                fatalError()
            },
            accessGroup: "accessGroupIdentifier"
        )

        subject.update(credentials, forUserID: userID)

        XCTAssertTrue(isCalled)
    }

    func test_delete() {
        var isCalled = false
        let userID = UserID(123)

        let expectedQuery: CFDictionary = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userID.value
        ] as CFDictionary

        subject = Subject(
            itemAdd: { (_, _) -> OSStatus in
                fatalError()
            },
            itemUpdate: { (query, value) -> OSStatus in
                fatalError()
            },
            itemCopy: { (_, _) -> OSStatus in
                fatalError()
            },
            itemDelete: { (query) -> OSStatus in
                isCalled = true
                XCTAssertEqual(query, expectedQuery)
                return errSecSuccess
            },
            accessGroup: "accessGroupIdentifier"
        )

        subject.delete(forUserID: userID)

        XCTAssertTrue(isCalled)
    }


    func test_credentials() {
        var isCalled = false

        let userID = UserID(123)

        let expectedQuery: CFDictionary = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userID.value,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecAttrAccessGroup as String: "accessGroupIdentifier",
        ] as CFDictionary

        let credentials = TokenCredential(oauthToken: "", oauthTokenSecret: "", userID: .init(123), screenName: "")
        let expectedData = try! JSONEncoder().encode(credentials)

        subject = Subject(
            itemAdd: { (_, _) -> OSStatus in
                fatalError()
            }, itemUpdate: { (_, _) -> OSStatus in
                fatalError()
            }, itemCopy: { (query, resultPointer) -> OSStatus in
                isCalled = true
                XCTAssertEqual(query, expectedQuery)
                resultPointer?.initialize(to: expectedData as CFData)
                return errSecSuccess
            },
            itemDelete: { (_) -> OSStatus in
                fatalError()
            },
            accessGroup: "accessGroupIdentifier"
        )

        let result = subject.credential(forUserID: userID)

        XCTAssertTrue(isCalled)
        XCTAssertEqual(result, credentials)
    }
}

