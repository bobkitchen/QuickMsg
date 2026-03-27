import Foundation

enum AppConstants {
    static let appGroupID = "group.com.bobkitchen.quickmsg"
    static let slotCount = 3
    static let slotsKey = "messageSlots"
    static let widgetKind = "QuickMsgWidget"

    static func defaultShortcutName(for index: Int) -> String {
        "QuickMsg_Slot\(index + 1)"
    }

    static let slotColors: [(red: Double, green: Double, blue: Double)] = [
        (0.0, 0.478, 1.0),   // Blue  #007AFF
        (0.204, 0.780, 0.349), // Green #34C759
        (1.0, 0.584, 0.0),   // Orange #FF9500
    ]

    static let defaultIcons = ["paperplane.fill", "bubble.left.fill", "location.fill"]
    static let defaultLabels = ["Message 1", "Message 2", "Message 3"]

    /// Debounce interval — ignore taps within this window after a send
    static let debounceInterval: TimeInterval = 5.0
    /// How long ✅/❌ states show before resetting to idle
    static let feedbackDisplayDuration: TimeInterval = 3.0
}
