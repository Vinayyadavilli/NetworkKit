// NetworkKit/Sources/NetworkKit/Core/Errors/NetworkError.swift

import Foundation

/// Exhaustive set of errors the network layer can throw.
public enum NetworkError: Error, LocalizedError, Equatable {

    // MARK: - Request Building

    case invalidURL(String)
    case encodingFailed(String)

    // MARK: - Transport

    case noInternetConnection
    case timeout
    case sslHandshakeFailed

    // MARK: - Response

    case noData
    case unexpectedStatusCode(Int)
    case unauthorized                  // 401 — triggers token refresh
    case forbidden                     // 403
    case notFound                      // 404
    case serverError(Int)              // 5xx

    // MARK: - Decoding

    case decodingFailed(String)

    // MARK: - Business Logic

    case apiError(APIErrorResponse)    // Server returned a structured error body

    // MARK: - Unknown

    case unknown(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):          return "Invalid URL: \(url)"
        case .encodingFailed(let msg):      return "Encoding failed: \(msg)"
        case .noInternetConnection:         return "No internet connection. Please check your network."
        case .timeout:                      return "The request timed out."
        case .sslHandshakeFailed:           return "SSL handshake failed. Check certificate pinning."
        case .noData:                       return "The server returned no data."
        case .unexpectedStatusCode(let c):  return "Unexpected HTTP status code: \(c)"
        case .unauthorized:                 return "Session expired. Please log in again."
        case .forbidden:                    return "You don't have permission to access this resource."
        case .notFound:                     return "The requested resource was not found."
        case .serverError(let c):           return "Server error (\(c)). Please try again later."
        case .decodingFailed(let msg):      return "Failed to decode response: \(msg)"
        case .apiError(let e):              return e.message
        case .unknown(let msg):             return "An unknown error occurred: \(msg)"
        }
    }

    // MARK: - Factory

    /// Converts a raw HTTP status code to the appropriate NetworkError.
    static func from(statusCode: Int) -> NetworkError {
        switch statusCode {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 500...599: return .serverError(statusCode)
        default: return .unexpectedStatusCode(statusCode)
        }
    }
}

// MARK: - Equatable support for APIErrorResponse

extension NetworkError {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL(let a), .invalidURL(let b)):   return a == b
        case (.noInternetConnection, .noInternetConnection): return true
        case (.timeout, .timeout):                       return true
        case (.noData, .noData):                         return true
        case (.unauthorized, .unauthorized):             return true
        case (.forbidden, .forbidden):                   return true
        case (.notFound, .notFound):                     return true
        case (.serverError(let a), .serverError(let b)): return a == b
        case (.decodingFailed(let a), .decodingFailed(let b)): return a == b
        default:                                         return false
        }
    }
}
