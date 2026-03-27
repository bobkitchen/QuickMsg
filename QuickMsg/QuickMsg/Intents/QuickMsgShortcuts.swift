import AppIntents

struct QuickMsgShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendMessageIntent(),
            phrases: [
                "Send a message with \(.applicationName)",
                "Send quick message with \(.applicationName)",
                "Open the gate with \(.applicationName)",
            ],
            shortTitle: "Send QuickMsg",
            systemImageName: "paperplane.fill"
        )
    }
}
