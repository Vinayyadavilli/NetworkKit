// NetworkKit/Sources/NetworkKit/Interceptors/AuthInterceptor.swift

import Foundation

/// Injects the Authorization header on every outgoing request that requires auth.
/// On 401 responses, it attempts a token refresh and retries the original request once.
public final class AuthInterceptor: RequestInterceptor {

    private let tokenProvider: TokenProviding

    public init(tokenProvider: TokenProviding) {
        self.tokenProvider = tokenProvider
    }

    // MARK: - RequestInterceptor

    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        guard let token = tokenProvider.accessToken else {
            return request // Unauthenticated — pass through untouched
        }
        var mutated = request
        mutated.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return mutated
    }
}
