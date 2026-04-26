import AppIntents
import Foundation
import WidgetKit

/// The single trigger that powers Lango's Siri voice path, CarPlay widget tap,
/// Home Screen widget tap, and main-app button taps.
///
/// **Driver-safety redline**: `authenticationPolicy = .alwaysAllowed` lets this
/// run on a locked device without prompting Face ID. Without it, every CarPlay
/// or Siri invocation would force the driver to unlock the phone — which is
/// the redline. The intent itself does no security-sensitive work; it just
/// posts a `messageKey` to the Worker, which is the source of truth for who
/// gets messaged and what gets sent.
struct SendMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "Send Lango Message"
    static let description: IntentDescription = IntentDescription(
        "Sends a preset WhatsApp message via the Lango Worker."
    )

    static let openAppWhenRun: Bool = false
    // Use `let` to satisfy Swift 6 strict concurrency — the value is immutable
    // and `let` satisfies the protocol's `var` requirement.
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "Slot Index")
    var slotIndex: Int

    init() {
        self.slotIndex = 0
    }

    init(slotIndex: Int) {
        self.slotIndex = slotIndex
    }

    func perform() async throws -> some IntentResult {
        let store = SlotStore.shared
        let slots = store.loadSlots()
        guard slotIndex >= 0 && slotIndex < slots.count else {
            return .result()
        }

        let slot = slots[slotIndex]
        guard slot.isConfigured && slot.isEnabled else {
            return .result()
        }

        // Debounce repeat taps within the window.
        guard store.canSend(slotIndex: slotIndex) else {
            return .result()
        }

        store.setSlotState(slotIndex, state: .sending)

        do {
            try await MessageService.send(messageKey: slot.messageKey)
            store.setSlotState(slotIndex, state: .sent)
        } catch {
            store.setSlotState(slotIndex, state: .failed)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: LangoConstants.widgetKind)
        return .result()
    }
}
