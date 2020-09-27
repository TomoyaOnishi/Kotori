import XCTest
@testable import Kotori

class URLEncodeTests: XCTestCase {

    typealias Subject = URLEncode

    func test_urlEncoded() {
        XCTContext.runActivity(named: "自分で定義した文字集合と一致すること") { _ in
            let allowedCharacter = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "-", ".", "_", "~"]
            let expected = CharacterSet(charactersIn: allowedCharacter.joined())

            XCTAssertTrue(URLEncode.allowedCharactersSet == expected)
        }

        XCTContext.runActivity(named: "Foundationが定義した文字集合から不要な文字を省いた結果と一致すること") { _ in
            var expected  = CharacterSet.urlQueryAllowed
            expected.remove(charactersIn: "\n:#/?@!$&'()*+,;=")

            XCTAssertTrue(URLEncode.allowedCharactersSet == expected)
        }
    }
}
