//
//  NetworkManager.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// The core networking engine that executes HTTP requests.
///
/// `NetworkManager` conforms to ``NetworkManagerProtocol`` and provides
/// a complete implementation for:
/// - Executing requests from ``Endpoint`` definitions or raw `URLRequest` objects.
/// - Applying ``RequestInterceptor`` chains for authentication, logging, etc.
/// - Validating HTTP status codes and decoding JSON responses.
///
/// ## Basic Usage
/// ```swift
/// let config = NetworkConfiguration(
///     baseURL: URL(string: "https://api.example.com")!
/// )
/// let manager = NetworkManager(configuration: config)
///
/// let posts: [Post] = try await manager.request(PostsEndpoint.list)
/// ```
///
/// ## With Interceptors
/// ```swift
/// let authInterceptor = AuthInterceptor(token: "abc123")
/// let manager = NetworkManager(
///     configuration: config,
///     interceptors: [authInterceptor]
/// )
/// ```
public final class NetworkManager: NetworkManagerProtocol, @unchecked Sendable {

    private let session: URLSession
    private let configuration: NetworkConfiguration
    private let requestBuilder: RequestBuilder
    private let responseHandler: ResponseHandler
    private let interceptors: [RequestInterceptor]

    /// Creates a new `NetworkManager`.
    ///
    /// - Parameters:
    ///   - configuration: The network configuration containing base URL and timeout.
    ///   - session: The `URLSession` to use. Defaults to `.shared`.
    ///   - decoder: A `JSONDecoder` for response decoding. Defaults to `JSONDecoder()`.
    ///   - interceptors: An array of ``RequestInterceptor`` to apply to every request.
    public init(
        configuration: NetworkConfiguration,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        interceptors: [RequestInterceptor] = []
    ) {
        self.configuration = configuration
        self.session = session
        self.requestBuilder = RequestBuilder(configuration: configuration)
        self.responseHandler = ResponseHandler(decoder: decoder)
        self.interceptors = interceptors
    }

    // MARK: - Endpoint-Based Request (Decodable)

    /// Executes a request from an ``Endpoint`` and decodes the JSON response.
    ///
    /// - Parameter endpoint: The endpoint definition.
    /// - Returns: The decoded response of type `T`.
    /// - Throws: A ``NetworkError`` if the request fails at any stage.
    public func request<T: Decodable>(
        _ endpoint: Endpoint
    ) async throws -> T {
        let urlRequest = try requestBuilder.build(from: endpoint)
        return try await executeRequest(urlRequest)
    }

    // MARK: - URLRequest-Based Request (Decodable)

    /// Executes a raw `URLRequest` and decodes the JSON response.
    ///
    /// - Parameter request: The URL request to execute.
    /// - Returns: The decoded response of type `T`.
    /// - Throws: A ``NetworkError`` if the request fails at any stage.
    public func request<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T {
        return try await executeRequest(request)
    }

    // MARK: - Endpoint-Based Request (Raw Data)

    /// Executes a request from an ``Endpoint`` and returns raw response data.
    ///
    /// Use this for non-JSON responses like images, files, or plain text.
    ///
    /// - Parameter endpoint: The endpoint definition.
    /// - Returns: The raw response `Data`.
    /// - Throws: A ``NetworkError`` if the request fails.
    public func requestData(
        _ endpoint: Endpoint
    ) async throws -> Data {
        let urlRequest = try requestBuilder.build(from: endpoint)
        return try await executeRawRequest(urlRequest)
    }

    // MARK: - Private Execution

    /// Core execution pipeline: apply interceptors → execute → validate → decode.
    private func executeRequest<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T {
        do {
            // Apply interceptors
            var adaptedRequest = request
            for interceptor in interceptors {
                do {
                    adaptedRequest = try await interceptor.adapt(adaptedRequest)
                } catch {
                    throw NetworkError.interceptorError(error)
                }
            }

            // Execute the request
            let (data, response) = try await session.data(for: adaptedRequest)

            // Validate and decode
            return try responseHandler.processResponse(T.self, data: data, response: response)

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }

    /// Core execution for raw data: apply interceptors → execute → validate → return data.
    private func executeRawRequest(
        _ request: URLRequest
    ) async throws -> Data {
        do {
            // Apply interceptors
            var adaptedRequest = request
            for interceptor in interceptors {
                do {
                    adaptedRequest = try await interceptor.adapt(adaptedRequest)
                } catch {
                    throw NetworkError.interceptorError(error)
                }
            }

            // Execute the request
            let (data, response) = try await session.data(for: adaptedRequest)

            // Validate status code
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            try responseHandler.validateStatusCode(httpResponse.statusCode)

            return data

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
}
