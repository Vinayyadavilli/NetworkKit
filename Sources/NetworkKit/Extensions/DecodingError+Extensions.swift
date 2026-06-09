// NetworkKit/Sources/NetworkKit/Extensions/DecodingError+Extensions.swift

import Foundation

extension DecodingError {

    /// Human-readable description pointing to exactly where decoding failed.
    var readableDescription: String {
        switch self {
        case .typeMismatch(let type, let context):
            return "Type mismatch for '\(type)' at '\(context.codingPath.readable)': \(context.debugDescription)"

        case .valueNotFound(let type, let context):
            return "Value not found for '\(type)' at '\(context.codingPath.readable)': \(context.debugDescription)"

        case .keyNotFound(let key, let context):
            return "Key '\(key.stringValue)' not found at '\(context.codingPath.readable)': \(context.debugDescription)"

        case .dataCorrupted(let context):
            return "Data corrupted at '\(context.codingPath.readable)': \(context.debugDescription)"

        @unknown default:
            return localizedDescription
        }
    }
}

private extension Array where Element == CodingKey {
    var readable: String {
        map { $0.stringValue }.joined(separator: " → ")
    }
}
