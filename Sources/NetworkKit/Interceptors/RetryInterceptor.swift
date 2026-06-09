// NetworkKit/Sources/NetworkKit/Interceptors/RetryInterceptor.swift

import Foundation

/// Retries failed requests up to `maxRetries` times with exponential back-off.
/// Only retries transient errors (timeout, no connection, 5xx).
public final class RetryInterceptor: ResponseInterceptor {

    private let maxRetries: Int
    private let baseDelay: TimeInterval

    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts. Default is 3.
    ///   - baseDelay: Initial delay in seconds before the first retry. Doubles each attempt.
    public init(maxRetries: Int = 3, baseDelay: TimeInterval = 0.5) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
    }

    // MARK: - ResponseInterceptor

    public func intercept(_ data: Data, response: HTTPURLResponse) async throws -> Data {
        // RetryInterceptor only observes — actual retry logic lives in NetworkClient
        // for retry-on-error flows. This hook is available for response mutation.
        return data
    }

    // MARK: - Public API (called by NetworkClient when needed)

    /// Returns true if the error is retryable.
    public func shouldRetry(error: NetworkError, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        switch error {
        case .timeout, .noInternetConnection, .serverError:
            return true
        default:
            return false
        }
    }

    /// Delay before the next retry attempt using exponential back-off with jitter.
    public func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.3)
        return exponential + jitter
    }
}
