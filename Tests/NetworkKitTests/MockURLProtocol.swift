//
//  MockURLProtocol.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// A custom `URLProtocol` subclass for intercepting and mocking network
/// requests in unit tests.
///
/// Use this to simulate server responses without making actual network calls.
///
/// ## Usage
/// ```swift
/// // Configure the mock to return specific data
/// MockURLProtocol.requestHandler = { request in
///     let data = """
///     {"id": 1, "title": "Test"}
///     """.data(using: .utf8)!
///     let response = HTTPURLResponse(
///         url: request.url!,
///         statusCode: 200,
///         httpVersion: nil,
///         headerFields: nil
///     )!
///     return (response, data)
/// }
///
/// // Create a URLSession that uses the mock
/// let config = URLSessionConfiguration.ephemeral
/// config.protocolClasses = [MockURLProtocol.self]
/// let session = URLSession(configuration: config)
/// ```
final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    /// A closure that receives the `URLRequest` and returns a tuple of
    /// `(HTTPURLResponse, Data)`.
    ///
    /// Set this before each test to define the mock behavior.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Captures the last request that was executed, for assertion in tests.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        MockURLProtocol.lastRequest = request

        guard let handler = MockURLProtocol.requestHandler else {
            let error = NSError(
                domain: "MockURLProtocol",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No request handler set"]
            )
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op: nothing to clean up for mock requests.
    }

    /// Resets the mock state. Call this in `tearDown()` of your tests.
    static func reset() {
        requestHandler = nil
        lastRequest = nil
    }
}
