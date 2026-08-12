//
//  RequestInterceptor.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// A protocol for intercepting and modifying outgoing network requests.
///
/// Use interceptors to inject authentication tokens, add common headers,
/// log requests, or perform any pre-flight modifications before a request
/// is sent to the server.
///
/// ## Example — Bearer Token Interceptor
/// ```swift
/// struct AuthInterceptor: RequestInterceptor {
///     let tokenProvider: () -> String?
///
///     func adapt(_ request: URLRequest) async throws -> URLRequest {
///         var request = request
///         if let token = tokenProvider() {
///             request.setValue(
///                 "Bearer \(token)",
///                 forHTTPHeaderField: "Authorization"
///             )
///         }
///         return request
///     }
/// }
/// ```
///
/// ## Example — API Key Interceptor
/// ```swift
/// struct APIKeyInterceptor: RequestInterceptor {
///     let apiKey: String
///
///     func adapt(_ request: URLRequest) async throws -> URLRequest {
///         var request = request
///         request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
///         return request
///     }
/// }
/// ```
public protocol RequestInterceptor: Sendable {

    /// Adapts the given `URLRequest` before it is executed.
    ///
    /// - Parameter request: The original request to modify.
    /// - Returns: The modified request.
    /// - Throws: An error if the interceptor cannot adapt the request
    ///   (e.g., token refresh failure).
    func adapt(_ request: URLRequest) async throws -> URLRequest
}
