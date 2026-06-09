// NetworkKit/Sources/NetworkKit/Client/NetworkClientBuilder.swift

import Foundation

/// Fluent builder for constructing a `NetworkClient` with interceptors and settings.
///
/// Usage:
/// ```swift
/// let client = NetworkClientBuilder()
///     .setSession(.shared)
///     .add(requestInterceptor: AuthInterceptor(tokenProvider: myStore))
///     .add(requestInterceptor: LoggingInterceptor())
///     .add(responseInterceptor: RetryInterceptor(maxRetries: 3))
///     .build()
/// ```
public final class NetworkClientBuilder {

    private var session: URLSession = .shared
    private var requestInterceptors: [RequestInterceptor] = []
    private var responseInterceptors: [ResponseInterceptor] = []
    private var decoder: JSONDecoder = .iso8601

    public init() {}

    @discardableResult
    public func setSession(_ session: URLSession) -> Self {
        self.session = session
        return self
    }

    @discardableResult
    public func add(requestInterceptor: RequestInterceptor) -> Self {
        requestInterceptors.append(requestInterceptor)
        return self
    }

    @discardableResult
    public func add(responseInterceptor: ResponseInterceptor) -> Self {
        responseInterceptors.append(responseInterceptor)
        return self
    }

    @discardableResult
    public func setDecoder(_ decoder: JSONDecoder) -> Self {
        self.decoder = decoder
        return self
    }

    public func build() -> NetworkClientProtocol {
        NetworkClient(
            session: session,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            decoder: decoder
        )
    }
}
