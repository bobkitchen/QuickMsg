import Foundation

/// Lango shared constants, accessed by the main app and the widget extension
/// via the App Group container.
enum LangoConstants {
    static let appGroupID = "group.com.bobkitchen.lango"
    static let keychainAccessGroup = "com.bobkitchen.lango.shared"
    static let slotCount = 3
    static let slotsKey = "messageSlots"
    static let widgetKind = "LangoWidget"

    // Keychain account name for the Worker shared secret.
    static let workerSecretKeychainAccount = "lango.worker.secret"
    // UserDefaults key for the Worker URL (lives in the App Group).
    static let workerURLKey = "lango.worker.url"

    static let slotColors: [(red: Double, green: Double, blue: Double)] = [
        (0.0, 0.478, 1.0),     // Blue   #007AFF
        (0.204, 0.780, 0.349), // Green  #34C759
        (1.0, 0.584, 0.0),     // Orange #FF9500
    ]

    static let defaultIcons = ["house.and.flag.fill", "car.fill", "checkmark.seal.fill"]
    static let defaultLabels = ["Open Gate", "On My Way", "Arrived"]
    static let defaultMessageKeys = ["gate_open", "eta_to_anna", "arrived_anna"]

    /// Debounce interval — ignore repeat taps within this window after a send.
    static let debounceInterval: TimeInterval = 5.0
    /// How long sent / failed states show before resetting to idle.
    static let feedbackDisplayDuration: TimeInterval = 3.0
}
