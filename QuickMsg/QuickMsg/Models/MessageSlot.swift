import Foundation

enum SlotState: String, Codable {
    case idle
    case sending
    case sent
    case failed
}

/// A configurable trigger surface. The phone holds only the opaque `messageKey`;
/// the Worker resolves that key to a Meta template and recipient phone number.
/// No phone numbers, no message bodies live on the device.
struct MessageSlot: Codable, Identifiable {
    let id: UUID
    var label: String
    var icon: String
    var messageKey: String
    var isEnabled: Bool
    var lastSentAt: Date?
    var slotState: SlotState
    var stateTimestamp: Date?
    var slotIndex: Int?

    init(
        slotIndex: Int,
        label: String? = nil,
        icon: String? = nil,
        messageKey: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.label = label ?? LangoConstants.defaultLabels[slotIndex]
        self.icon = icon ?? LangoConstants.defaultIcons[slotIndex]
        self.messageKey = messageKey ?? LangoConstants.defaultMessageKeys[slotIndex]
        self.isEnabled = isEnabled
        self.slotState = .idle
        self.stateTimestamp = nil
        self.lastSentAt = nil
        self.slotIndex = slotIndex
    }

    /// A slot is configured once it has a non-empty messageKey.
    /// The Worker is the source of truth for whether that key actually routes
    /// somewhere — a typo here yields an `unknown_key` error at send time.
    var isConfigured: Bool {
        !messageKey.isEmpty
    }
}
