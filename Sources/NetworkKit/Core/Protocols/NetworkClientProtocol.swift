// NetworkKit/Sources/NetworkKit/Core/Protocols/NetworkClientProtocol.swift

import Foundation

/// The primary interface callers depend on.
/// Program to this protocol — never to the concrete NetworkClient.
public protocol NetworkClientProtocol: Sendable {

    /// Sends a request and returns the decoded response.
    @discardableResult
    func send<R: NetworkRequest>(_ request: R) async throws -> R.Response

    /// Sends a request, returning raw Data along with the HTTP response.
    func sendRaw<R: NetworkRequest>(_ request: R) async throws -> (Data, HTTPURLResponse)
}
