// NetworkKit/Sources/NetworkKit/Core/Models/APIErrorResponse.swift

import Foundation

/// Standard server-side error payload.
/// Adapt the property names to match your backend's error schema.
public struct APIErrorResponse: Decodable, Equatable, Sendable {
    public let code: String       // e.g. "USER_NOT_FOUND"
    public let message: String    // Human-readable description
    public let details: [String]? // Optional field-level validation errors

    public init(code: String, message: String, details: [String]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}
