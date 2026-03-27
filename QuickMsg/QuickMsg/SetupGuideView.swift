import SwiftUI

struct SetupGuideView: View {
    let slot: MessageSlot
    let slotIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0

    private var accentColor: Color {
        let c = AppConstants.slotColors[slotIndex % AppConstants.slotColors.count]
        return Color(red: c.red, green: c.green, blue: c.blue)
    }

    private var steps: [(icon: String, title: String, detail: String)] {
        [
            (
                "apps.iphone",
                "Open Shortcuts",
                "We'll open the Shortcuts app for you. Tap the + button to create a new shortcut."
            ),
            (
                "character.cursor.ibeam",
                "Name it exactly:",
                "Tap the shortcut name at the top and type:\n\n\(slot.shortcutName)\n\nThis must match exactly (case-sensitive)."
            ),
            (
                "magnifyingglass",
                "Add WhatsApp action",
                "Tap \"Add Action\", then search for \"WhatsApp\". Select \"Send Message\"."
            ),
            (
                "person.fill",
                "Set recipient",
                "In the WhatsApp action, tap \"Recipients\" and select:\n\n\(slot.recipientName.isEmpty ? "(configure recipient first)" : slot.recipientName)"
            ),
            (
                "text.bubble.fill",
                "Set message",
                "Tap the message field and type:\n\n\"\(slot.messageText.isEmpty ? "(configure message first)" : slot.messageText)\""
            ),
            (
                "eye.slash.fill",
                "Hide when run",
                "Tap the expand arrow (▼) on the WhatsApp action, then toggle \"Show When Run\" OFF.\n\nThis is critical — it makes the send silent."
            ),
            (
                "checkmark.circle.fill",
                "Save & Test",
                "Tap \"Done\" to save the shortcut. Then come back to QuickMsg and tap \"Test\" to verify it works."
            ),
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .tint(accentColor)
                    .padding(.horizontal)
                    .padding(.top)

                Text("Step \(currentStep + 1) of \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Spacer()

                // Step content
                let step = steps[currentStep]
                VStack(spacing: 20) {
                    Image(systemName: step.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(accentColor)

                    Text(step.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(step.detail)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }
                .padding()

                Spacer()

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if currentStep == 0 {
                        Button {
                            ShortcutLauncher.openShortcutsApp()
                            withAnimation { currentStep += 1 }
                        } label: {
                            Label("Open Shortcuts", systemImage: "arrow.up.forward.app.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentColor)
                    } else if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation { currentStep += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentColor)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Setup: \(slot.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
