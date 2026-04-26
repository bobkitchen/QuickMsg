import AppIntents

/// Registers Siri voice phrases that fire `SendMessageIntent`.
///
/// Note on naming: `AppShortcutsProvider` is the App Intents Siri-vocabulary
/// registration. It is **not** the Shortcuts.app x-callback chain — that path
/// was dropped in v2 of the brief. This is what teaches Siri to recognise
/// "Hey Siri, open the gate" and bind it to the intent.
///
/// Slot 0 is canonically the gate-open slot — its position is meaningful
/// because the Siri phrase is statically wired to `slotIndex: 0`. The
/// Settings UI labels and orders accordingly.
struct LangoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendMessageIntent(slotIndex: 0),
            phrases: [
                "Open the gate with \(.applicationName)",
                "Open gate with \(.applicationName)",
                "\(.applicationName) open gate",
            ],
            shortTitle: "Open Gate",
            systemImageName: "house.and.flag.fill"
        )

        AppShortcut(
            intent: SendMessageIntent(slotIndex: 1),
            phrases: [
                "Send on my way with \(.applicationName)",
                "On my way with \(.applicationName)",
            ],
            shortTitle: "On My Way",
            systemImageName: "car.fill"
        )

        AppShortcut(
            intent: SendMessageIntent(slotIndex: 2),
            phrases: [
                "Send arrived with \(.applicationName)",
                "I have arrived with \(.applicationName)",
            ],
            shortTitle: "Arrived",
            systemImageName: "checkmark.seal.fill"
        )
    }
}
