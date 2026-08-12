//
//  RequestBody.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// Describes the body content of an HTTP request.
///
/// Use this enum to specify how the request body should be encoded
/// when building a ``URLRequest`` from an ``Endpoint``.
public enum RequestBody: Sendable {

    /// JSON-encoded body from an `Encodable` value.
    ///
    /// The request will automatically set `Content-Type: application/json`.
    /// Pass a custom `JSONEncoder` if you need specific encoding strategies
    /// (e.g., snake_case key encoding, custom date formats).
    ///
    /// - Parameters:
    ///   - value: The encodable value to serialize.
    ///   - encoder: A `JSONEncoder` instance (defaults to `JSONEncoder()`).
    case json(any Encodable & Sendable, encoder: JSONEncoder = JSONEncoder())

    /// URL-encoded form body (`application/x-www-form-urlencoded`).
    ///
    /// The request will automatically set `Content-Type: application/x-www-form-urlencoded`.
    ///
    /// - Parameter fields: Key-value pairs to encode.
    case formData([String: String])

    /// Multipart form-data body (`multipart/form-data`).
    ///
    /// Use this for file uploads (images, documents, etc.) along with
    /// optional text fields.
    ///
    /// - Parameters:
    ///   - files: An array of ``MultipartFile`` representing files to upload.
    ///   - fields: Optional text fields to include alongside the files.
    case multipart(files: [MultipartFile], fields: [String: String] = [:])

    /// Raw data body with a custom content type.
    ///
    /// Use this when you need to send pre-encoded data (e.g., XML, plain text,
    /// or binary data).
    ///
    /// - Parameters:
    ///   - data: The raw body data.
    ///   - contentType: The MIME type for the `Content-Type` header.
    case raw(Data, contentType: String)
}
