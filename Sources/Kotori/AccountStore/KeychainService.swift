import Foundation
import Security

struct KeychainService {

    typealias ItemAdd = (_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    typealias ItemUpdate = (_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus
    typealias ItemCopy = (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    typealias ItemDelete = (_ query: CFDictionary) -> OSStatus

    private let itemAdd: ItemAdd
    private let itemUpdate: ItemUpdate
    private let itemCopy: ItemCopy
    private let itemDelete: ItemDelete
    private let accessGroup: String

    init(
        itemAdd: @escaping Self.ItemAdd,
        itemUpdate: @escaping Self.ItemUpdate,
        itemCopy: @escaping Self.ItemCopy,
        itemDelete: @escaping Self.ItemDelete,
        accessGroup: String
    ) {
        self.itemAdd = itemAdd
        self.itemUpdate = itemUpdate
        self.itemCopy = itemCopy
        self.itemDelete = itemDelete
        self.accessGroup = accessGroup
    }

    func add(_ credential: TokenCredential) {
        let account = credential.userID
        let data = try! JSONEncoder().encode(credential)
        let query: CFDictionary = [kSecClass: kSecClassGenericPassword,
                                   kSecAttrAccount as String: account.value,
                                   kSecAttrAccessGroup as String: accessGroup,
                                   kSecValueData as String: data,
                                   kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary

        _ = itemAdd(query as CFDictionary, nil)
    }

    func credential(forUserID userID: UserID) -> TokenCredential? {
        let findQuery: CFDictionary = [kSecClass: kSecClassGenericPassword,
                                       kSecAttrAccount: userID.value,
                                       kSecAttrAccessGroup as String: accessGroup,
                                       kSecReturnData: kCFBooleanTrue!] as CFDictionary

        var result: CFTypeRef?
        _ = itemCopy(findQuery, &result)

        if let result = result, let data = result as? Data {
            do {
                return try JSONDecoder().decode(TokenCredential.self, from: data)
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }

        return nil
    }

    func allCredentials() -> [TokenCredential] {
        let findQuery: CFDictionary = [kSecClass: kSecClassGenericPassword,
                                       kSecReturnData: kCFBooleanTrue!,
                                       kSecAttrAccessGroup as String: accessGroup,
                                       kSecMatchLimit: kSecMatchLimitAll
        ] as CFDictionary

        var result: CFTypeRef?
        _ = itemCopy(findQuery, &result)

        if let result = result, let data = result as? [Data] {
            return data.compactMap({ try? JSONDecoder().decode(TokenCredential.self, from: $0) })
        }

        return []
    }

    func update(_ credential: TokenCredential, forUserID userID: UserID) {
        let data = try! JSONEncoder().encode(credential)
        let query = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrAccount as String: userID.value,
                     kSecAttrAccessGroup as String: accessGroup,
        ] as CFDictionary

        let value: [String: Any] = [
            kSecValueData as String: data
        ]

        _ = itemUpdate(query as CFDictionary, value as CFDictionary)
    }

    func delete(forUserID userID: UserID) {
        let query = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrAccount as String: userID.value] as CFDictionary
        _ = itemDelete(query)
    }
}
