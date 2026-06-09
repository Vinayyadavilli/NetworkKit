// NetworkKit/Sources/NetworkKit/Extensions/JSONDecoder+Extensions.swift

import Foundation

public extension JSONDecoder {

    /// Decoder configured for ISO 8601 dates — the most common API date format.
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// Decoder configured for Unix timestamp dates.
    static var unixTimestamp: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

public extension JSONEncoder {

    /// Encoder configured for ISO 8601 dates, snake_case keys.
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
