// NetworkKit/Sources/NetworkKit/Client/NetworkClient.swift

import Foundation

/// Production implementation of `NetworkClientProtocol`.
/// Inject this (or a mock) wherever network calls are needed.
public final class NetworkClient: NetworkClientProtocol, Sendable {

    // MARK: - Dependencies

    private let session: URLSession
    private let requestInterceptors: [RequestInterceptor]
    private let responseInterceptors: [ResponseInterceptor]
    private let decoder: JSONDecoder
    private let logger: NetworkLogger

    // MARK: - Init

    public init(
        session: URLSession = .shared,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        decoder: JSONDecoder = .iso8601
    ) {
        self.session = session
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.decoder = decoder
        self.logger = NetworkLogger()
    }

    // MARK: - NetworkClientProtocol

    @discardableResult
    public func send<R: NetworkRequest>(_ request: R) async throws -> R.Response {
        let (data, _) = try await sendRaw(request)
        return try decode(R.Response.self, from: data)
    }

    public func sendRaw<R: NetworkRequest>(_ request: R) async throws -> (Data, HTTPURLResponse) {
        var urlRequest = try request.asURLRequest()

        // Run all request interceptors in order
        for interceptor in requestInterceptors {
            urlRequest = try await interceptor.intercept(urlRequest)
        }

        logger.log(request: urlRequest)

        let (data, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Response is not an HTTPURLResponse")
        }

        logger.log(response: httpResponse, data: data)

        // Validate HTTP status
        try validateStatus(httpResponse.statusCode, data: data)

        // Run all response interceptors in order
        var processedData = data
        for interceptor in responseInterceptors {
            processedData = try await interceptor.intercept(processedData, response: httpResponse)
        }

        return (processedData, httpResponse)
    }

    // MARK: - Private Helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        }
    }

    private func validateStatus(_ statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200...299:
            return // Success — no error thrown

        case 401:
            throw NetworkError.unauthorized

        case 403:
            throw NetworkError.forbidden

        case 404:
            throw NetworkError.notFound

        default:
            // Attempt to decode a structured API error body
            if let apiError = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data) {
                throw NetworkError.apiError(apiError)
            }
            throw NetworkError.from(statusCode: statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Handle Empty response types
        if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T {
            return empty
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decodingFailed(error.readableDescription)
        }
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .serverCertificateUntrusted, .clientCertificateRejected:
            return .sslHandshakeFailed
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
