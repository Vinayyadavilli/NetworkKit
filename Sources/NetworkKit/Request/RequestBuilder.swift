//
//  RequestBuilder.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// Builds `URLRequest` instances from ``Endpoint`` definitions or manual parameters.
///
/// `RequestBuilder` takes a ``NetworkConfiguration`` and assembles fully-formed
/// `URLRequest` objects with the correct URL, HTTP method, headers, query
/// parameters, and encoded body.
public struct RequestBuilder: Sendable {

    private let configuration: NetworkConfiguration

    public init(configuration: NetworkConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Build from Endpoint

    /// Builds a `URLRequest` from an ``Endpoint`` definition.
    ///
    /// - Parameter endpoint: The endpoint describing the request.
    /// - Returns: A fully-configured `URLRequest`.
    /// - Throws: ``NetworkError/invalidURL`` if the URL cannot be constructed,
    ///   or ``NetworkError/encodingError(_:)`` if the body cannot be encoded.
    public func build(from endpoint: Endpoint) throws -> URLRequest {
        // Construct URL with query parameters
        let url = try buildURL(path: endpoint.path, queryItems: endpoint.queryItems)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = configuration.timeout

        // Apply endpoint-specific headers
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Encode body
        if let body = endpoint.body {
            try encodeBody(body, into: &request)
        }

        return request
    }

    // MARK: - Build Manually (Legacy)

    /// Builds a `URLRequest` from individual parameters.
    ///
    /// - Parameters:
    ///   - path: The URL path component.
    ///   - method: The HTTP method.
    ///   - headers: Optional HTTP headers.
    ///   - queryItems: Optional URL query parameters.
    ///   - body: Optional raw body data.
    /// - Returns: A fully-configured `URLRequest`.
    /// - Throws: ``NetworkError/invalidURL`` if the URL cannot be constructed.
    public func build(
        path: String,
        method: HTTPMethod,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        let url = try buildURL(path: path, queryItems: queryItems)

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = configuration.timeout

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body
        return request
    }

    // MARK: - Private Helpers

    /// Constructs a URL from the base URL, path, and optional query items.
    private func buildURL(
        path: String,
        queryItems: [URLQueryItem]?
    ) throws -> URL {
        let fullURL = configuration.baseURL.appendingPathComponent(path)

        guard var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        return url
    }

    /// Encodes a ``RequestBody`` into the given `URLRequest`.
    private func encodeBody(
        _ body: RequestBody,
        into request: inout URLRequest
    ) throws {
        switch body {

        case .json(let encodable, let encoder):
            do {
                request.httpBody = try encoder.encode(AnyEncodable(encodable))
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw NetworkError.encodingError(error)
            }

        case .formData(let fields):
            let encoded = fields
                .sorted(by: { $0.key < $1.key })
                .map { key, value in
                    let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                    let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                    return "\(escapedKey)=\(escapedValue)"
                }
                .joined(separator: "&")
            request.httpBody = encoded.data(using: .utf8)
            request.setValue(
                "application/x-www-form-urlencoded",
                forHTTPHeaderField: "Content-Type"
            )

        case .multipart(let files, let fields):
            let builder = MultipartFormDataBuilder()
            request.httpBody = builder.build(files: files, fields: fields)
            request.setValue(builder.contentType, forHTTPHeaderField: "Content-Type")

        case .raw(let data, let contentType):
            request.httpBody = data
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
    }
}

// MARK: - AnyEncodable Type-Eraser

/// A type-erased wrapper that allows encoding any `Encodable` value.
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
