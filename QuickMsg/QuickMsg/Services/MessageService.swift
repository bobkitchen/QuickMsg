import Foundation

enum LangoError: Error, CustomStringConvertible {
    case notConfigured
    case invalidURL(String)
    case workerFailed(status: Int, body: String)
    case unknownKey(String)

    var description: String {
        switch self {
        case .notConfigured:
            return "Worker URL or secret not set"
        case .invalidURL(let s):
            return "Invalid Worker URL: \(s)"
        case .workerFailed(let status, let body):
            return "Worker returned \(status): \(body)"
        case .unknownKey(let key):
            return "Worker doesn't recognise messageKey '\(key)'"
        }
    }
}

/// The phone's only outbound channel. Posts a `messageKey` to the Worker
/// with a shared-secret header. The Worker resolves key → template + recipient
/// and fires the Meta Cloud API call.
///
/// No phone numbers, no template names, no Meta token live on the device.
enum MessageService {
    static func send(messageKey: String) async throws {
        guard AppConfig.isConfigured else {
            throw LangoError.notConfigured
        }

        let urlString = AppConfig.workerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        // Accept Worker URLs with or without a trailing slash; always POST to /send.
        let base = urlString.hasSuffix("/") ? String(urlString.dropLast()) : urlString
        guard let url = URL(string: base + "/send") else {
            throw LangoError.invalidURL(urlString)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(AppConfig.workerSecret, forHTTPHeaderField: "X-Lango-Secret")
        req.httpBody = try JSONEncoder().encode(["key": messageKey])
        req.timeoutInterval = 15

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw LangoError.workerFailed(status: -1, body: "no HTTP response")
        }

        if http.statusCode == 404,
           let body = try? JSONDecoder().decode(WorkerError.self, from: data),
           body.error == "unknown_key" {
            throw LangoError.unknownKey(messageKey)
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LangoError.workerFailed(status: http.statusCode, body: body)
        }
    }

    private struct WorkerError: Decodable {
        let ok: Bool
        let error: String?
    }
}
