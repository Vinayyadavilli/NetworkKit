// NetworkKit/Sources/NetworkKit/Utils/EmptyResponse.swift

import Foundation

/// Use as the `Response` type for requests that return no body (e.g. DELETE, 204 No Content).
///
/// Example:
/// ```swift
/// struct DeleteUserRequest: NetworkRequest {
///     typealias Response = EmptyResponse
///     let method: HTTPMethod = .DELETE
///     let path = "/users/123"
/// }
/// ```
public struct EmptyResponse: Decodable, Sendable {
    public init() {}
}
