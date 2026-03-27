import SwiftUI
import WidgetKit

@main
struct QuickMsgApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleURL(url)
                }
                .onAppear {
                    checkPendingSend()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkPendingSend()
            }
        }
    }

    /// Check if the widget requested a send via shared UserDefaults
    private func checkPendingSend() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        guard let slotIndex = defaults?.object(forKey: "pendingSendSlotIndex") as? Int,
              let timestamp = defaults?.double(forKey: "pendingSendTimestamp"),
              timestamp > 0 else { return }

        // Only process if the request is recent (within 10 seconds)
        let requestAge = Date().timeIntervalSince1970 - timestamp
        guard requestAge < 10 else {
            clearPendingSend()
            return
        }

        // Clear the pending flag immediately to avoid re-processing
        clearPendingSend()

        // Fire the shortcut
        ShortcutLauncher.runShortcut(for: slotIndex)
    }

    private func clearPendingSend() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        defaults?.removeObject(forKey: "pendingSendSlotIndex")
        defaults?.removeObject(forKey: "pendingSendTimestamp")
    }

    /// Handle x-callback URLs from the Shortcuts app
    private func handleURL(_ url: URL) {
        guard url.scheme == "quickmsg",
              let host = url.host() else { return }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "sent":
            if let slotIndex = pathComponents.first.flatMap(Int.init) {
                SlotStore.shared.setSlotState(slotIndex, state: .sent)
            }

        case "failed":
            if let slotIndex = pathComponents.first.flatMap(Int.init) {
                SlotStore.shared.setSlotState(slotIndex, state: .failed)
            }

        default:
            break
        }
    }
}
