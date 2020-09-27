import Foundation

class MockURLProtocol: URLProtocol {
    static var makeResponseHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))!

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func stopLoading() { }

    override func startLoading() {
        precondition(MockURLProtocol.makeResponseHandler != nil)
        do {
            let (response, data)  = try MockURLProtocol.makeResponseHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch  {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

