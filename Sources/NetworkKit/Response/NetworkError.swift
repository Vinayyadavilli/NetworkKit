//
//  NetworkError.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

public enum NetworkError: Error, Sendable {

    /// The URL could not be constructed from the endpoint configuration.
    case invalidURL

    /// The server returned a response that is not an HTTPURLResponse.
    case invalidResponse

    /// The response body was empty when data was expected.
    case noData

    /// HTTP 401 — the request requires authentication.
    case unauthorized

    /// HTTP 403 — the server refuses to authorize the request.
    case forbidden

    /// HTTP 404 — the requested resource was not found.
    case notFound

    /// HTTP 5xx — server-side error with the associated status code.
    case serverError(Int)

    /// Failed to decode the response body into the expected type.
    case decodingError(Error)

    /// Failed to encode the request body.
    case encodingError(Error)

    /// The underlying URLSession request failed.
    case requestFailed(Error)

    /// A request interceptor threw an error.
    case interceptorError(Error)
}
