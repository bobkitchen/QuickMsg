import UIKit

@MainActor
enum ShortcutLauncher {
    /// Launches a shortcut via x-callback-url and updates slot state.
    /// Called from the main app after the widget requests a send.
    /// Note: The widget already set state to .sending — skip the canSend debounce check
    /// since this IS the initial send triggered by the widget handoff.
    static func runShortcut(for slotIndex: Int) {
        let store = SlotStore.shared
        let slots = store.loadSlots()
        guard slotIndex >= 0 && slotIndex < slots.count else { return }
        let slot = slots[slotIndex]

        guard slot.isConfigured else { return }

        // State is already .sending (set by the widget intent).
        // Build the shortcuts x-callback URL.
        guard let encodedName = slot.shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let successURL = "quickmsg://sent/\(slotIndex)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let errorURL = "quickmsg://failed/\(slotIndex)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            store.setSlotState(slotIndex, state: .failed)
            return
        }

        let urlString = "shortcuts://x-callback-url/run-shortcut?name=\(encodedName)&x-success=\(successURL)&x-error=\(errorURL)"

        guard let url = URL(string: urlString) else {
            store.setSlotState(slotIndex, state: .failed)
            return
        }

        UIApplication.shared.open(url) { success in
            if !success {
                store.setSlotState(slotIndex, state: .failed)
            }
        }
    }

    /// Check if the Shortcuts app is available
    static var isShortcutsAvailable: Bool {
        UIApplication.shared.canOpenURL(URL(string: "shortcuts://")!)
    }

    /// Check if WhatsApp is installed
    static var isWhatsAppInstalled: Bool {
        UIApplication.shared.canOpenURL(URL(string: "whatsapp://")!)
    }

    /// Open the Shortcuts app
    static func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}
