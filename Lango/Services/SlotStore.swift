import Foundation
import WidgetKit

/// Persists slot configuration in App Group UserDefaults so the main app and
/// the widget extension share state. Drives the idle / sending / sent / failed
/// state machine that the widget visualises.
final class SlotStore: @unchecked Sendable {
    static let shared = SlotStore()

    private let defaults: UserDefaults

    init() {
        self.defaults = UserDefaults(suiteName: LangoConstants.appGroupID) ?? .standard
    }

    // MARK: - Slot CRUD

    func loadSlots() -> [MessageSlot] {
        guard let data = defaults.data(forKey: LangoConstants.slotsKey),
              let slots = try? JSONDecoder().decode([MessageSlot].self, from: data) else {
            return createDefaultSlots()
        }
        // Ensure we always have exactly slotCount slots — pad with defaults if
        // the persisted array was shorter (older versions, etc.).
        if slots.count < LangoConstants.slotCount {
            var padded = slots
            for i in slots.count..<LangoConstants.slotCount {
                padded.append(MessageSlot(slotIndex: i))
            }
            saveSlots(padded)
            return padded
        }
        return slots
    }

    func saveSlots(_ slots: [MessageSlot]) {
        if let data = try? JSONEncoder().encode(slots) {
            defaults.set(data, forKey: LangoConstants.slotsKey)
        }
    }

    func updateSlot(at index: Int, _ transform: (inout MessageSlot) -> Void) {
        var slots = loadSlots()
        guard index >= 0 && index < slots.count else { return }
        transform(&slots[index])
        saveSlots(slots)
    }

    // MARK: - State Management

    func setSlotState(_ index: Int, state: SlotState) {
        updateSlot(at: index) { slot in
            slot.slotState = state
            slot.stateTimestamp = Date()
            if state == .sent {
                slot.lastSentAt = Date()
            }
        }
        WidgetCenter.shared.reloadTimelines(ofKind: LangoConstants.widgetKind)
    }

    func resetExpiredStates() {
        var slots = loadSlots()
        var changed = false
        let now = Date()
        for i in slots.indices {
            if let timestamp = slots[i].stateTimestamp,
               (slots[i].slotState == .sent || slots[i].slotState == .failed),
               now.timeIntervalSince(timestamp) > LangoConstants.feedbackDisplayDuration {
                slots[i].slotState = .idle
                slots[i].stateTimestamp = nil
                changed = true
            }
        }
        if changed {
            saveSlots(slots)
        }
    }

    /// Returns false when a slot is unconfigured / disabled, or when it is
    /// already in flight within the debounce window. Used by the widget tap
    /// handler to avoid double-fires from accidental repeat taps.
    func canSend(slotIndex: Int) -> Bool {
        let slots = loadSlots()
        guard slotIndex >= 0 && slotIndex < slots.count else { return false }
        let slot = slots[slotIndex]
        guard slot.isConfigured && slot.isEnabled else { return false }
        if let timestamp = slot.stateTimestamp, slot.slotState == .sending {
            if Date().timeIntervalSince(timestamp) < LangoConstants.debounceInterval {
                return false
            }
        }
        return true
    }

    // MARK: - Private

    private func createDefaultSlots() -> [MessageSlot] {
        let slots = (0..<LangoConstants.slotCount).map { MessageSlot(slotIndex: $0) }
        saveSlots(slots)
        return slots
    }
}
