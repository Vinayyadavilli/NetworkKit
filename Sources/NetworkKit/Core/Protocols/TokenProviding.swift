// NetworkKit/Sources/NetworkKit/Core/Protocols/TokenProviding.swift

import Foundation

/// Abstracts the token store so NetworkKit never imports Keychain or UserDefaults directly.
public protocol TokenProviding: Sendable {

    /// Current valid access token, or nil if the user is unauthenticated.
    var accessToken: String? { get }

    /// Refreshes the access token and returns the new value.
    /// Throws if the refresh fails (e.g. expired refresh token).
    func refreshToken() async throws -> String
}
