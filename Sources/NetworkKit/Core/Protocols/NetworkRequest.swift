// NetworkKit/Sources/NetworkKit/Core/Protocols/NetworkRequest.swift

import Foundation

/// Defines the contract every API request must fulfil.
/// Each endpoint in your app creates a struct/class conforming to this protocol.
public protocol NetworkRequest {

    /// The expected decoded response type.
    associatedtype Response: Decodable

    /// Full base URL — override per-request to hit a different host.
    var baseURL: URL { get }

    /// Path appended to baseURL, e.g. "/users/123"
    var path: String { get }

    /// HTTP verb.
    var method: HTTPMethod { get }

    /// Headers specific to this request (merged with global headers).
    var headers: HTTPHeaders { get }

    /// URL query parameters appended to the final URL.
    var queryParameters: QueryParameters? { get }

    /// JSON-encodable body. Ignored for GET/DELETE.
    var body: Encodable? { get }

    /// When true, the AuthInterceptor injects the Bearer token.
    var requiresAuthentication: Bool { get }

    /// Cache policy for this specific request.
    var cachePolicy: URLRequest.CachePolicy { get }

    /// Timeout in seconds. Defaults to NetworkConfiguration value.
    var timeoutInterval: TimeInterval { get }
}

// MARK: - Default Implementations

public extension NetworkRequest {

    var baseURL: URL {
        NetworkConfiguration.shared.baseURL
    }

    var headers: HTTPHeaders { [:] }

    var queryParameters: QueryParameters? { nil }

    var body: Encodable? { nil }

    var requiresAuthentication: Bool { true }

    var cachePolicy: URLRequest.CachePolicy { .useProtocolCachePolicy }

    var timeoutInterval: TimeInterval {
        NetworkConfiguration.shared.timeoutInterval
    }

    /// Builds a fully-configured URLRequest from the protocol properties.
    func asURLRequest() throws -> URLRequest {
        let url = try buildURL()
        var request = URLRequest(url: url,
                                 cachePolicy: cachePolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue

        // Merge global headers first, then request-specific (request wins on conflict)
        let merged = NetworkConfiguration.shared.globalHeaders.merging(headers) { _, new in new }
        merged.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body {
            request.httpBody = try JSONEncoder.iso8601.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    // MARK: Private helpers

    private func buildURL() throws -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                       resolvingAgainstBaseURL: true)
        if let params = queryParameters, !params.isEmpty {
            components?.queryItems = params
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            throw NetworkError.invalidURL(baseURL.appendingPathComponent(path).absoluteString)
        }
        return url
    }
}
