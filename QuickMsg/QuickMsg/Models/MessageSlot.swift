import Foundation

enum SlotState: String, Codable {
    case idle
    case sending
    case sent
    case failed
}

struct MessageSlot: Codable, Identifiable {
    let id: UUID
    var label: String
    var icon: String
    var recipientName: String
    var recipientPhone: String
    var messageText: String
    var shortcutName: String
    var isEnabled: Bool
    var lastSentAt: Date?
    var slotState: SlotState
    var stateTimestamp: Date?

    /// The slot index (0-based), derived from shortcut name convention
    var slotIndex: Int?

    init(
        slotIndex: Int,
        label: String? = nil,
        icon: String? = nil,
        recipientName: String = "",
        recipientPhone: String = "",
        messageText: String = "",
        shortcutName: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.label = label ?? AppConstants.defaultLabels[slotIndex]
        self.icon = icon ?? AppConstants.defaultIcons[slotIndex]
        self.recipientName = recipientName
        self.recipientPhone = recipientPhone
        self.messageText = messageText
        self.shortcutName = shortcutName ?? label ?? AppConstants.defaultLabels[slotIndex]
        self.isEnabled = isEnabled
        self.slotState = .idle
        self.stateTimestamp = nil
        self.lastSentAt = nil
        self.slotIndex = slotIndex
    }

    var isConfigured: Bool {
        !recipientPhone.isEmpty && !messageText.isEmpty
    }

    var isShortcutSetup: Bool {
        isConfigured && !shortcutName.isEmpty
    }
}
