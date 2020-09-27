import Foundation
import CryptoKit

/// Generate oauth signature for OAuth1.0
struct OAuthSignature {
    let httpMethod: String
    let baseURL: URL
    let oauthParameters: [String: String]
    let parameters: [String: String]
    let credential: RequiredCredential

    struct RequiredCredential {
        let consumerSecret: String
        let oauthTokenSecret: String
    }

    init(
        httpMethod: String,
        baseURL: URL,
        oauthParameters: [String: String],
        parameters: [String: String],
        credential: RequiredCredential
    ) throws {
        precondition(baseURL.query == nil)
        self.httpMethod = httpMethod
        self.baseURL = baseURL
        self.oauthParameters = oauthParameters
        self.parameters = parameters
        self.credential = credential
    }

    func makeParametersString() -> String {
        let allParameters = oauthParameters.merging(parameters, uniquingKeysWith: { $1 }).sorted(by: { $0 < $1 })

        let encodedKeyValueStrings = allParameters.map({ (key, value) -> String in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
            let encoededValue = value.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
            return [encodedKey, encoededValue].joined(separator: "=")
        })

        let output = encodedKeyValueStrings.joined(separator: "&")

        return output
    }

    func makeSignatureBaseString() -> String {
        let httpMethod = self.httpMethod.uppercased()
        let URLString = self.baseURL.absoluteString.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
        let parametersString = makeParametersString().addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
        return [httpMethod, URLString, parametersString].joined(separator: "&")
    }

    func makeSignKey() -> String {
        let encodedConsumerKey = credential.consumerSecret.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
        let encodedConsumerSecret = credential.oauthTokenSecret.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
        return encodedConsumerKey + "&" + encodedConsumerSecret
    }

    func calculate() -> String {
        let baseString = makeSignatureBaseString()
        let keyString = makeSignKey()
        let key = SymmetricKey(data: keyString.data(using: .utf8)!)
        let messageData = baseString.data(using: .utf8)!
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: messageData, using: key)
        return Data(signature).base64EncodedString()
    }

}
