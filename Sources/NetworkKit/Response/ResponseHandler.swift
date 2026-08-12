//
//  ResponseHandler.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// Handles HTTP response validation and data decoding.
///
/// `ResponseHandler` is responsible for:
/// - Validating HTTP status codes and mapping them to ``NetworkError``.
/// - Decoding response data into `Decodable` types using a configurable `JSONDecoder`.
public struct ResponseHandler: Sendable {

    private let decoder: JSONDecoder

    /// Creates a new `ResponseHandler` with the given JSON decoder.
    ///
    /// - Parameter decoder: A `JSONDecoder` instance. Defaults to a standard
    ///   `JSONDecoder()`. Pass a custom decoder for snake_case keys, custom
    ///   date formats, etc.
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    // MARK: - Status Code Validation

    /// Validates an HTTP status code and throws the appropriate ``NetworkError``.
    ///
    /// - Parameter statusCode: The HTTP status code from the response.
    /// - Throws: A ``NetworkError`` for non-2xx status codes.
    public func validateStatusCode(_ statusCode: Int) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400...499:
            throw NetworkError.serverError(statusCode)
        case 500...599:
            throw NetworkError.serverError(statusCode)
        default:
            throw NetworkError.serverError(statusCode)
        }
    }

    // MARK: - Response Decoding

    /// Decodes response data into a `Decodable` type.
    ///
    /// - Parameters:
    ///   - type: The type to decode the data into.
    ///   - data: The raw response data.
    /// - Returns: The decoded value of type `T`.
    /// - Throws: ``NetworkError/decodingError(_:)`` if decoding fails.
    public func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    // MARK: - Full Response Processing

    /// Processes a full HTTP response: validates the status code, then
    /// decodes the body into the requested type.
    ///
    /// - Parameters:
    ///   - type: The expected `Decodable` response type.
    ///   - data: The raw response data.
    ///   - response: The `URLResponse` from the network call.
    /// - Returns: The decoded value of type `T`.
    /// - Throws: ``NetworkError/invalidResponse`` if the response is not HTTP,
    ///   or any status code / decoding error.
    public func processResponse<T: Decodable>(
        _ type: T.Type,
        data: Data,
        response: URLResponse
    ) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        try validateStatusCode(httpResponse.statusCode)
        return try decode(type, from: data)
    }
}
