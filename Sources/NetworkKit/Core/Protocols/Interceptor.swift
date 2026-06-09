// NetworkKit/Sources/NetworkKit/Core/Protocols/Interceptor.swift

import Foundation

/// Intercepts and mutates a request before it is sent.
public protocol RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

/// Intercepts a response (data + HTTPURLResponse) after it is received.
public protocol ResponseInterceptor {
    func intercept(_ data: Data, response: HTTPURLResponse) async throws -> Data
}

/// Combines both request and response interception in one type.
public typealias Interceptor = RequestInterceptor & ResponseInterceptor
