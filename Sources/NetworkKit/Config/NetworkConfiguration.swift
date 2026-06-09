// NetworkKit/Sources/NetworkKit/Config/NetworkConfiguration.swift

import Foundation

/// Single source of truth for all network-wide settings.
/// Configure once at app launch: `NetworkConfiguration.shared.configure(with: .production)`
public final class NetworkConfiguration: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = NetworkConfiguration()
    private init() {}

    // MARK: - Properties

    public private(set) var baseURL: URL = URL(string: "https://api.example.com/v1")!
    public private(set) var timeoutInterval: TimeInterval = 30
    public private(set) var globalHeaders: HTTPHeaders = [
        "Accept": "application/json",
        "Accept-Language": Locale.preferredLanguages.first ?? "en"
    ]
    public private(set) var environment: Environment = .production
    public private(set) var logLevel: LogLevel = .none

    // MARK: - Configuration

    public func configure(with settings: Settings) {
        self.baseURL = settings.baseURL
        self.timeoutInterval = settings.timeoutInterval
        self.globalHeaders = globalHeaders.merging(settings.additionalHeaders) { _, new in new }
        self.environment = settings.environment
        self.logLevel = settings.logLevel
    }
}

// MARK: - Settings

public extension NetworkConfiguration {

    struct Settings {
        public let baseURL: URL
        public let environment: Environment
        public let timeoutInterval: TimeInterval
        public let additionalHeaders: HTTPHeaders
        public let logLevel: LogLevel

        public init(
            baseURL: URL,
            environment: Environment = .production,
            timeoutInterval: TimeInterval = 30,
            additionalHeaders: HTTPHeaders = [:],
            logLevel: LogLevel = .none
        ) {
            self.baseURL = baseURL
            self.environment = environment
            self.timeoutInterval = timeoutInterval
            self.additionalHeaders = additionalHeaders
            self.logLevel = logLevel
        }
    }
}

// MARK: - Environment

public enum Environment: String, Sendable {
    case development
    case staging
    case production
}

// MARK: - LogLevel

public enum LogLevel: Int, Sendable {
    case none      = 0   // Silent
    case error     = 1   // Errors only
    case info      = 2   // Request + response summaries
    case verbose   = 3   // Full headers, bodies
}
