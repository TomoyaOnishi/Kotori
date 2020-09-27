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
        case initFailed(underlyingError: Error)
        case appendFailed(underlyingError: Error)
        case finalizeFailed(underlyingError: Error)
        case giveup(underlyingError: Error?, recoveryHint: String)
    }
}
