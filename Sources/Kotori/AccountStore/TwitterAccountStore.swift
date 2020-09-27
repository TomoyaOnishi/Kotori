import Foundation

public protocol TwitterAccountStoreProtocol {
    func credential(for userID: UserID) -> TwitterCredential?
    func allCredentials() -> [TwitterCredential]
    func deleteCredential(for userID: UserID)
    func add(_ credential: TwitterCredential)
}

public final class TwitterAccountStore: TwitterAccountStoreProtocol {

    private let keychainAccessGroup: String

    public init(keychainAccessGroup: String) {
        self.keychainAccessGroup = keychainAccessGroup
    }

    public func credential(for userID: UserID) -> TwitterCredential? {
        let keychainService = KeychainService(itemAdd: SecItemAdd, itemUpdate: SecItemUpdate, itemCopy: SecItemCopyMatching, itemDelete: SecItemDelete, accessGroup: keychainAccessGroup)
        return keychainService.credential(forUserID: userID)
    }

    public func allCredentials() -> [TwitterCredential] {
        let keychainService = KeychainService(itemAdd: SecItemAdd, itemUpdate: SecItemUpdate, itemCopy: SecItemCopyMatching, itemDelete: SecItemDelete, accessGroup: keychainAccessGroup)
        return keychainService.allCredentials()
    }

    public func deleteCredential(for userID: UserID) {
        let keychainService = KeychainService(itemAdd: SecItemAdd, itemUpdate: SecItemUpdate, itemCopy: SecItemCopyMatching, itemDelete: SecItemDelete, accessGroup: keychainAccessGroup)
        return keychainService.delete(forUserID: userID)
    }

    public func add(_ credential: TwitterCredential) {
        let keychainService = KeychainService(itemAdd: SecItemAdd, itemUpdate: SecItemUpdate, itemCopy: SecItemCopyMatching, itemDelete: SecItemDelete, accessGroup: keychainAccessGroup)
        if let _ = keychainService.credential(forUserID: credential.userID) {
            keychainService.update(credential, forUserID: credential.userID)
        } else {
            keychainService.add(credential)
        }
    }
}
