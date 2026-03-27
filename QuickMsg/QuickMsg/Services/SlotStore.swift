import Foundation
import WidgetKit

final class SlotStore: @unchecked Sendable {
    static let shared = SlotStore()

    private let defaults: UserDefaults

    init() {
        self.defaults = UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
    }

    // MARK: - Slot CRUD

    func loadSlots() -> [MessageSlot] {
        guard let data = defaults.data(forKey: AppConstants.slotsKey),
              let slots = try? JSONDecoder().decode([MessageSlot].self, from: data) else {
            return createDefaultSlots()
        }
        // Ensure we always have exactly slotCount slots
        if slots.count < AppConstants.slotCount {
            var padded = slots
            for i in slots.count..<AppConstants.slotCount {
                padded.append(MessageSlot(slotIndex: i))
            }
            saveSlots(padded)
            return padded
        }
        // Migrate: sync shortcutName to label for existing slots that still
        // have the old "QuickMsg_SlotN" naming convention.
        var migrated = slots
        var didMigrate = false
        for i in migrated.indices {
            if migrated[i].shortcutName.hasPrefix("QuickMsg_Slot") && migrated[i].isConfigured {
                migrated[i].shortcutName = migrated[i].label
                didMigrate = true
            }
        }
        if didMigrate {
            saveSlots(migrated)
        }
        return didMigrate ? migrated : slots
    }

    func saveSlots(_ slots: [MessageSlot]) {
        if let data = try? JSONEncoder().encode(slots) {
            defaults.set(data, forKey: AppConstants.slotsKey)
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
        WidgetCenter.shared.reloadTimelines(ofKind: AppConstants.widgetKind)
    }

    func resetExpiredStates() {
        var slots = loadSlots()
        var changed = false
        let now = Date()
        for i in slots.indices {
            if let timestamp = slots[i].stateTimestamp,
               (slots[i].slotState == .sent || slots[i].slotState == .failed),
               now.timeIntervalSince(timestamp) > AppConstants.feedbackDisplayDuration {
                slots[i].slotState = .idle
                slots[i].stateTimestamp = nil
                changed = true
            }
        }
        if changed {
            saveSlots(slots)
        }
    }

    func canSend(slotIndex: Int) -> Bool {
        let slots = loadSlots()
        guard slotIndex >= 0 && slotIndex < slots.count else { return false }
        let slot = slots[slotIndex]
        guard slot.isConfigured && slot.isEnabled else { return false }
        // Debounce check
        if let timestamp = slot.stateTimestamp, slot.slotState == .sending {
            if Date().timeIntervalSince(timestamp) < AppConstants.debounceInterval {
                return false
            }
        }
        return true
    }

    // MARK: - Private

    private func createDefaultSlots() -> [MessageSlot] {
        let slots = (0..<AppConstants.slotCount).map { MessageSlot(slotIndex: $0) }
        saveSlots(slots)
        return slots
    }
}
