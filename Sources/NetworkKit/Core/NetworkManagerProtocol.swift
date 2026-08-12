//
//  NetworkManagerProtocol.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// Protocol defining the public API for making network requests.
///
/// Conform to this protocol to create custom or mock network managers
/// for dependency injection and unit testing.
public protocol NetworkManagerProtocol: Sendable {

    /// Executes a request built from an ``Endpoint`` and decodes the response.
    ///
    /// - Parameter endpoint: The endpoint definition to execute.
    /// - Returns: The decoded response of type `T`.
    /// - Throws: A ``NetworkError`` if the request fails.
    func request<T: Decodable>(
        _ endpoint: Endpoint
    ) async throws -> T

    /// Executes a raw `URLRequest` and decodes the response.
    ///
    /// - Parameter request: The URL request to execute.
    /// - Returns: The decoded response of type `T`.
    /// - Throws: A ``NetworkError`` if the request fails.
    func request<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T

    /// Executes a request built from an ``Endpoint`` and returns raw `Data`.
    ///
    /// Use this for responses that are not JSON (e.g., images, files, plain text).
    ///
    /// - Parameter endpoint: The endpoint definition to execute.
    /// - Returns: The raw response `Data`.
    /// - Throws: A ``NetworkError`` if the request fails.
    func requestData(
        _ endpoint: Endpoint
    ) async throws -> Data
}
