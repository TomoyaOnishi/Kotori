/// Generate authorization header string for OAuth1.0.
struct AuthorizationHeader {
    static let key = "Authorization"
    let oauthParameters: [String: String]

    public init(oauthParameters: [String: String]) {
        self.oauthParameters = oauthParameters
    }

    public func makeString() -> String {
        let encodedKeyValueStrings = oauthParameters.sorted(by: { $0 < $1 }).map { element -> String in
            let encodedKey = element.key.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
            let encodedValue = element.value.addingPercentEncoding(withAllowedCharacters: URLEncode.allowedCharactersSet)!
            return encodedKey + "=" + ["\"", encodedValue, "\""].joined()
        }
        let output = "OAuth " + encodedKeyValueStrings.joined(separator: ", ")
        return output
    }
}
