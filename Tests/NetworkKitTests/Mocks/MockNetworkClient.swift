// NetworkKit/Tests/NetworkKitTests/Mocks/MockNetworkClient.swift

import Foundation
@testable import NetworkKit

/// Drop-in test double for `NetworkClientProtocol`.
/// Pre-load it with a `Result` to control what each test receives.
final class MockNetworkClient: NetworkClientProtocol {

    // MARK: - Stubbing

    /// Set before each test to control the outcome.
    var stubbedResult: Any?
    var stubbedError: Error?

    // MARK: - Call Tracking

    private(set) var sentRequests: [Any] = []
    var callCount: Int { sentRequests.count }
    var lastRequest: Any? { sentRequests.last }

    func reset() {
        stubbedResult = nil
        stubbedError = nil
        sentRequests.removeAll()
    }

    // MARK: - NetworkClientProtocol

    func send<R: NetworkRequest>(_ request: R) async throws -> R.Response {
        sentRequests.append(request)
        if let error = stubbedError { throw error }
        guard let result = stubbedResult as? R.Response else {
            throw NetworkError.decodingFailed("MockNetworkClient: no stub set for \(R.Response.self)")
        }
        return result
    }

    func sendRaw<R: NetworkRequest>(_ request: R) async throws -> (Data, HTTPURLResponse) {
        sentRequests.append(request)
        if let error = stubbedError { throw error }
        let url = URL(string: "https://mock.test")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(), response)
    }
}
