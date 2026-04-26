import Foundation

/// Reads/writes Worker configuration. Worker URL lives in App Group UserDefaults
/// (so the widget extension can read it). The Worker shared secret lives in
/// the Keychain (with the shared access group).
///
/// Implemented as an enum (no instance state) — `UserDefaults(suiteName:)` is
/// thread-safe and cheap to resolve, and this avoids non-Sendable storage in
/// what would otherwise be a shared-mutable singleton under Swift 6.
enum AppConfig {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: LangoConstants.appGroupID) ?? .standard
    }

    static var workerURL: String {
        get { defaults.string(forKey: LangoConstants.workerURLKey) ?? "" }
        set {
            defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines),
                         forKey: LangoConstants.workerURLKey)
        }
    }

    static var workerSecret: String {
        KeychainService.getSecret() ?? ""
    }

    static func setWorkerSecret(_ secret: String) throws {
        let trimmed = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainService.deleteSecret()
        } else {
            try KeychainService.setSecret(trimmed)
        }
    }

    static var isConfigured: Bool {
        !workerURL.isEmpty && !workerSecret.isEmpty
    }
}
