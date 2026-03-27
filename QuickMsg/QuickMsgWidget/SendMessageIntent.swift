import AppIntents
import Foundation

struct SendMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "Send QuickMsg"
    static let description: IntentDescription = "Sends a preset WhatsApp message via Shortcuts"

    static let openAppWhenRun: Bool = true

    @Parameter(title: "Slot Index")
    var slotIndex: Int

    init() {
        self.slotIndex = 0
    }

    init(slotIndex: Int) {
        self.slotIndex = slotIndex
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Update slot state to sending first (shared via App Group)
        SlotStore.shared.setSlotState(slotIndex, state: .sending)

        // Write the pending send request to shared UserDefaults
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        defaults?.set(slotIndex, forKey: "pendingSendSlotIndex")
        defaults?.set(Date().timeIntervalSince1970, forKey: "pendingSendTimestamp")
        defaults?.synchronize()

        return .result()
    }
}
