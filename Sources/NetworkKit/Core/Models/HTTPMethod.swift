// NetworkKit/Sources/NetworkKit/Core/Models/HTTPMethod.swift

import Foundation

/// Standard HTTP methods used across requests.
public enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    case HEAD
}
