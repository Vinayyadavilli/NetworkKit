// NetworkKit/Sources/NetworkKit/Plugins/NetworkLogger.swift

import Foundation

/// Internal logger used by `NetworkClient` for response logging.
final class NetworkLogger: Sendable {

    func log(request: URLRequest) {
        guard NetworkConfiguration.shared.logLevel >= .info else { return }
        print("▶︎ [\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? "")")
    }

    func log(response: HTTPURLResponse, data: Data) {
        let level = NetworkConfiguration.shared.logLevel
        guard level >= .info else { return }

        let statusEmoji = (200...299).contains(response.statusCode) ? "✅" : "❌"
        var output = "\n┌─── \(statusEmoji) NetworkKit Response ──────────────────────\n"
        output += "│ Status : \(response.statusCode)\n"
        output += "│ URL    : \(response.url?.absoluteString ?? "")\n"

        if level == .verbose {
            if let json = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let text = String(data: pretty, encoding: .utf8) {
                output += "│ Body:\n\(text.split(separator: "\n").map { "│   \($0)" }.joined(separator: "\n"))\n"
            }
        }

        output += "└──────────────────────────────────────────────────"
        print(output)
    }
}

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
