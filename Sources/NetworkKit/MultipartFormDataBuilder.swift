//
//  MultipartFormDataBuilder.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

/// Utility to construct `multipart/form-data` HTTP request bodies.
///
/// This builder generates the properly formatted multipart body data
/// including boundary separators, content dispositions, and MIME types
/// for both text fields and binary file uploads.
public struct MultipartFormDataBuilder: Sendable {

    /// A unique boundary string used to separate parts in the multipart body.
    public let boundary: String

    /// The `Content-Type` header value including the boundary.
    ///
    /// Use this to set the request's `Content-Type` header:
    /// ```
    /// "multipart/form-data; boundary=<boundary>"
    /// ```
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    /// Creates a new `MultipartFormDataBuilder` with a unique boundary string.
    public init() {
        self.boundary = "Boundary-\(UUID().uuidString)"
    }

    /// Builds the complete multipart/form-data body.
    ///
    /// - Parameters:
    ///   - files: An array of ``MultipartFile`` to include as file parts.
    ///   - fields: Key-value text fields to include as form parts.
    /// - Returns: The encoded `Data` ready to be used as the HTTP body.
    public func build(
        files: [MultipartFile],
        fields: [String: String] = [:]
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        // Append text fields
        for (key, value) in fields.sorted(by: { $0.key < $1.key }) {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)")
            body.append(lineBreak)
            body.append("\(value)\(lineBreak)")
        }

        // Append file parts
        for file in files {
            body.append("--\(boundary)\(lineBreak)")
            body.append(
                "Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\(lineBreak)"
            )
            body.append("Content-Type: \(file.mimeType)\(lineBreak)")
            body.append(lineBreak)
            body.append(file.data)
            body.append(lineBreak)
        }

        // Closing boundary
        body.append("--\(boundary)--\(lineBreak)")

        return body
    }
}

// MARK: - Data Extension for String Appending

extension Data {

    /// Appends a UTF-8 encoded string to the data buffer.
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
