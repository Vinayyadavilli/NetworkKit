// NetworkKit/Tests/NetworkKitTests/Mocks/MockTokenProvider.swift

import Foundation
@testable import NetworkKit

final class MockTokenProvider: TokenProviding {
    var accessToken: String? = "mock-access-token"
    var shouldFailRefresh = false
    private(set) var refreshCallCount = 0

    func refreshToken() async throws -> String {
        refreshCallCount += 1
        if shouldFailRefresh { throw NetworkError.unauthorized }
        return "mock-refreshed-token"
    }
}
