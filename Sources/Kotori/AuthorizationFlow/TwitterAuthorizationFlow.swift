import Foundation
import Combine

public class TwitterAuthorizationFlow {
    let clientCredential: ClientCredential
    let urlSession: URLSession
    var cancellers: Set<AnyCancellable> = .init()
    var temporaryCredentialRequestResponse: AuthorizationFlow.TemporaryCredentialRequest.Response?
    var resourceOwnerAuthorizationResponse: AuthorizationFlow.ResourceOwnerAuthorization.Response?
    public var authorizationPublisher: PassthroughSubject<TwitterCredential, TwitterAuthorizationFlow.AuthorizationFlowError> = .init()
    
    public init(clientCredential: ClientCredential, urlSession: URLSession) {
        self.clientCredential = clientCredential
        self.urlSession = urlSession
    }
    
    public func authorize() -> AnyPublisher<TwitterCredential, TwitterAuthorizationFlow.AuthorizationFlowError> {
        authorizationPublisher = .init()

        let temporaryCredentialRequest = AuthorizationFlow.TemporaryCredentialRequest(
            timestamp: Date(),
            nonce: UUID(),
            requiredCredential: .init(consumerKey: clientCredential.consumerKey,
                                      consumerSecret: clientCredential.consumerSecret,
                                      callbackURL: clientCredential.callbackURL)
        )
        
        URLSession.DataTaskPublisher(request: temporaryCredentialRequest.urlRequest, session: urlSession)
            .map({ $0.data })
            .map(AuthorizationFlow.TemporaryCredentialRequest.Response.init)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self.authorizationPublisher.send(completion: .failure(.authorizationFailed(underlyingError: error, recoveryHint: nil)))
                }
            }, receiveValue: handleTemporaryCredentialRequest(_:))
            .store(in: &self.cancellers)
        
        return authorizationPublisher.eraseToAnyPublisher()
    }
    
    func handleTemporaryCredentialRequest(_ response: AuthorizationFlow.TemporaryCredentialRequest.Response) {
        temporaryCredentialRequestResponse = response
        precondition(response.oauthCallbackConfirmed == "true")
        
        let resourceOwnerAuthorization = AuthorizationFlow.ResourceOwnerAuthorization(
            timestamp: Date(),
            nonce: UUID(),
            requiredCredential: .init(oauthToken: response.oauthToken)
        )
        
        NotificationCenter.default.post(name: TwitterAuthorizationFlow.resourceOwnerAuthorizationOpenURL, object: resourceOwnerAuthorization.openURL)
    }
    
    public func handleCallbackFromTwitter(url: URL) {
        guard url.absoluteString.starts(with: clientCredential.callbackURL.absoluteString) else {
            authorizationPublisher.send(completion: .failure(.authorizationFailed(underlyingError: nil, recoveryHint: "The callback url is invalid.")))
            return
        }
        handleResourceOwnerAuthorization(AuthorizationFlow.ResourceOwnerAuthorization.Response(url))
    }
    
    func handleResourceOwnerAuthorization(_ response: AuthorizationFlow.ResourceOwnerAuthorization.Response) {
        resourceOwnerAuthorizationResponse = response
        precondition(resourceOwnerAuthorizationResponse?.oauthToken == response.oauthToken)
        
        let tokenRequest = AuthorizationFlow.TokenRequest(
            timestamp: Date(),
            nonce: UUID(),
            requiredCredential: .init(
                consumerKey: clientCredential.consumerKey,
                consumerSecret: clientCredential.consumerSecret,
                oauthToken: response.oauthToken,
                oauthVerifier: response.oauthVerifier
            )
        )
        
        URLSession.DataTaskPublisher(request: tokenRequest.urlRequest, session: urlSession)
            .map({ $0.data })
            .map(AuthorizationFlow.TokenRequest.Response.init)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self.authorizationPublisher.send(completion: .failure(.authorizationFailed(underlyingError: error, recoveryHint: nil)))
                }
            }, receiveValue: handleToken(_:))
            .store(in: &self.cancellers)
    }
    
    func handleToken(_ response: AuthorizationFlow.TokenRequest.Response) {
        let tokenCredential: TwitterCredential = .init(
            oauthToken: response.oauthToken,
            oauthTokenSecret: response.oauthTokenSecret,
            userID: response.userID,
            screenName: response.screenName
        )
        
        authorizationPublisher.send(tokenCredential)
        authorizationPublisher.send(completion: .finished)
    }
}
