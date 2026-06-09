// NetworkKit/Sources/NetworkKit/Interceptors/LoggingInterceptor.swift

import Foundation

/// Logs outgoing requests to the console.
/// Respects `NetworkConfiguration.shared.logLevel` — silent in production.
public final class LoggingInterceptor: RequestInterceptor {

    public init() {}

    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        let level = NetworkConfiguration.shared.logLevel
        guard level != .none else { return request }

        var output = "\n┌─── 📤 NetworkKit Request ───────────────────────\n"
        output += "│ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "")\n"

        if level == .verbose {
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                output += "│ Headers:\n"
                headers.sorted { $0.key < $1.key }.forEach {
                    let value = $0.key.lowercased() == "authorization" ? "Bearer ***" : $0.value
                    output += "│   \($0.key): \(value)\n"
                }
            }
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let text = String(data: pretty, encoding: .utf8) {
                output += "│ Body:\n\(text.split(separator: "\n").map { "│   \($0)" }.joined(separator: "\n"))\n"
            }
        }

        output += "└──────────────────────────────────────────────────"
        print(output)
        return request
    }
}
