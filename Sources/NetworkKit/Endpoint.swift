//
//  Endpoint.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// A protocol that defines all the components of an HTTP request.
///
/// Conform to this protocol to create type-safe, reusable API endpoint
/// definitions. Each endpoint encapsulates the path, HTTP method, headers,
/// query parameters, and body needed for a network request.
///
/// ## Example
/// ```swift
/// enum UserEndpoint: Endpoint {
///     case getProfile(userId: Int)
///     case updateProfile(userId: Int, name: String)
///     case uploadAvatar(userId: Int, imageData: Data)
///
///     var path: String {
///         switch self {
///         case .getProfile(let id), .updateProfile(let id, _), .uploadAvatar(let id, _):
///             return "/users/\(id)"
///         }
///     }
///
///     var method: HTTPMethod {
///         switch self {
///         case .getProfile: return .GET
///         case .updateProfile: return .PUT
///         case .uploadAvatar: return .POST
///         }
///     }
///
///     var headers: [String: String]? { nil }
///     var queryItems: [URLQueryItem]? { nil }
///
///     var body: RequestBody? {
///         switch self {
///         case .getProfile:
///             return nil
///         case .updateProfile(_, let name):
///             return .json(["name": name])
///         case .uploadAvatar(_, let imageData):
///             let file = MultipartFile(
///                 fieldName: "avatar",
///                 fileName: "avatar.jpg",
///                 mimeType: "image/jpeg",
///                 data: imageData
///             )
///             return .multipart(files: [file])
///         }
///     }
/// }
/// ```
public protocol Endpoint: Sendable {

    /// The URL path component (e.g., "/users/123", "/posts").
    ///
    /// This is appended to the `baseURL` from ``NetworkConfiguration``.
    var path: String { get }

    /// The HTTP method to use for this request.
    var method: HTTPMethod { get }

    /// Optional HTTP headers specific to this endpoint.
    ///
    /// These are merged with any headers set by interceptors.
    /// Endpoint-specific headers take precedence.
    var headers: [String: String]? { get }

    /// Optional URL query parameters (e.g., `?page=1&limit=20`).
    var queryItems: [URLQueryItem]? { get }

    /// Optional request body.
    ///
    /// Use ``RequestBody/json(_:encoder:)`` for JSON,
    /// ``RequestBody/formData(_:)`` for URL-encoded forms,
    /// ``RequestBody/multipart(files:fields:)`` for file uploads,
    /// or ``RequestBody/raw(_:contentType:)`` for custom data.
    var body: RequestBody? { get }
}
