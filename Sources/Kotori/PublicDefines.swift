import Foundation

public extension TwitterAuthorizationFlow {
    static let resourceOwnerAuthorizationOpenURL: Notification.Name = .init("resourceOwnerAuthorizationOpenURL")

    enum AuthorizationFlowError: Error {
        case authorizationFailed(underlyingError: Error?, recoveryHint: String?)
    }
}

public typealias TwitterCredential = TokenCredential

public class Kotori {
}

public extension TwitterMediaUploader {
    enum MediaUploadError: Error {
        case initFailed
        case appendFailed
        case finalizeFailed
        case giveup(recoveryHint: String)
    }
}
