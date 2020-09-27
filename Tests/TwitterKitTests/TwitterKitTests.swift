import XCTest
@testable import TwitterKit

final class TwitterKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TwitterKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
