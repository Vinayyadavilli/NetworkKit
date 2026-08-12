//
//  NetworkManagerTests.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation
import Testing
@testable import NetworkKit

// MARK: - Test Models

struct MockPost: Codable, Sendable, Equatable {
    let id: Int
    let title: String
}

// MARK: - Test Interceptor

struct MockInterceptor: RequestInterceptor {
    let headerKey: String
    let headerValue: String

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
        return request
    }
}

struct FailingInterceptor: RequestInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        throw NSError(domain: "TestError", code: 999, userInfo: nil)
    }
}

// MARK: - Helper

/// Creates a `NetworkManager` configured with a mock `URLSession`.
private func makeMockManager(
    interceptors: [RequestInterceptor] = [],
    decoder: JSONDecoder = JSONDecoder()
) -> NetworkManager {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)

    return NetworkManager(
        configuration: NetworkConfiguration(
            baseURL: URL(string: "https://api.test.com")!
        ),
        session: session,
        decoder: decoder,
        interceptors: interceptors
    )
}

/// A simple test endpoint.
private struct MockEndpoint: Endpoint {
    var path: String = "/posts"
    var method: HTTPMethod = .GET
    var headers: [String: String]? = nil
    var queryItems: [URLQueryItem]? = nil
    var body: RequestBody? = nil
}

// MARK: - NetworkManager Tests

@Suite("NetworkManager Tests", .serialized)
struct NetworkManagerTests {

    init() {
        MockURLProtocol.reset()
    }

    // MARK: - Successful Responses

    @Test("decodes a successful JSON response from endpoint")
    func decodesSuccessfulResponse() async throws {
        let expectedPosts = [
            MockPost(id: 1, title: "Hello"),
            MockPost(id: 2, title: "World")
        ]

        MockURLProtocol.requestHandler = { request in
            let data = try JSONEncoder().encode(expectedPosts)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let manager = makeMockManager()
        let posts: [MockPost] = try await manager.request(MockEndpoint())

        #expect(posts == expectedPosts)
    }

    @Test("returns raw data from requestData")
    func returnsRawData() async throws {
        let expectedData = "raw response content".data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedData)
        }

        let manager = makeMockManager()
        let data = try await manager.requestData(MockEndpoint())

        #expect(data == expectedData)
    }

    // MARK: - Error Handling

    @Test("throws unauthorized for 401 status code")
    func throwsUnauthorized() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let manager = makeMockManager()

        await #expect(throws: NetworkError.self) {
            let _: MockPost = try await manager.request(MockEndpoint())
        }
    }

    @Test("throws forbidden for 403 status code")
    func throwsForbidden() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let manager = makeMockManager()

        await #expect(throws: NetworkError.self) {
            let _: MockPost = try await manager.request(MockEndpoint())
        }
    }

    @Test("throws notFound for 404 status code")
    func throwsNotFound() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let manager = makeMockManager()

        await #expect(throws: NetworkError.self) {
            let _: MockPost = try await manager.request(MockEndpoint())
        }
    }

    @Test("throws serverError for 500 status code")
    func throwsServerError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let manager = makeMockManager()

        await #expect(throws: NetworkError.self) {
            let _: MockPost = try await manager.request(MockEndpoint())
        }
    }

    @Test("throws decodingError for malformed JSON")
    func throwsDecodingError() async throws {
        MockURLProtocol.requestHandler = { request in
            let data = "not-valid-json".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let manager = makeMockManager()

        await #expect(throws: NetworkError.self) {
            let _: MockPost = try await manager.request(MockEndpoint())
        }
    }

    // MARK: - Interceptors

    @Test("interceptor adds custom header to request")
    func interceptorAddsHeader() async throws {
        let expectedPost = MockPost(id: 1, title: "Test")

        MockURLProtocol.requestHandler = { request in
            // Verify the interceptor added the header
            #expect(request.value(forHTTPHeaderField: "X-Custom") == "test-value")

            let data = try JSONEncoder().encode(expectedPost)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let manager = makeMockManager(
            interceptors: [
                MockInterceptor(headerKey: "X-Custom", headerValue: "test-value")
            ]
        )

        let post: MockPost = try await manager.request(MockEndpoint())
        #expect(post == expectedPost)
    }

    @Test("multiple interceptors are applied in order")
    func multipleInterceptors() async throws {
        let expectedPost = MockPost(id: 1, title: "Multi")

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer abc")
            #expect(request.value(forHTTPHeaderField: "X-Request-Id") == "req-123")

            let data = try JSONEncoder().encode(expectedPost)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let manager = makeMockManager(
            interceptors: [
                MockInterceptor(headerKey: "Authorization", headerValue: "Bearer abc"),
                MockInterceptor(headerKey: "X-Request-Id", headerValue: "req-123")
            ]
        )

        let post: MockPost = try await manager.request(MockEndpoint())
        #expect(post == expectedPost)
    }

    @Test("failing interceptor throws interceptorError")
    func failingInterceptorThrows() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let manager = makeMockManager(
            interceptors: [FailingInterceptor()]
        )

        await #expect(throws: NetworkError.self) {
            let _: MockPost = try await manager.request(MockEndpoint())
        }
    }

    // MARK: - URLRequest-based Request

    @Test("executes raw URLRequest and decodes response")
    func executesRawURLRequest() async throws {
        let expectedPost = MockPost(id: 42, title: "Direct Request")

        MockURLProtocol.requestHandler = { request in
            let data = try JSONEncoder().encode(expectedPost)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let manager = makeMockManager()
        let urlRequest = URLRequest(url: URL(string: "https://api.test.com/posts/42")!)
        let post: MockPost = try await manager.request(urlRequest)

        #expect(post == expectedPost)
    }
}
