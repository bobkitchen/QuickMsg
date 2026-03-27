import SwiftUI
import UIKit

struct SetupGuideView: View {
    let slot: MessageSlot
    let slotIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var copiedName = false
    @State private var verifying = false
    @State private var verifyResult: VerifyResult?

    enum VerifyResult {
        case success
        case failed(String)
    }

    private var accentColor: Color {
        let c = AppConstants.slotColors[slotIndex % AppConstants.slotColors.count]
        return Color(red: c.red, green: c.green, blue: c.blue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // Step 1: Copy name & open Shortcuts
                    stepCard(
                        number: 1,
                        icon: "doc.on.clipboard",
                        title: "Create a new shortcut",
                        detail: "Tap the button below to copy the shortcut name and open the Shortcuts app. Then tap + to create a new shortcut and **paste** the name."
                    ) {
                        copyAndOpenButton
                    }

                    // Step 2: Add WhatsApp action
                    stepCard(
                        number: 2,
                        icon: "magnifyingglass",
                        title: "Add WhatsApp Send Message",
                        detail: "Tap \"Add Action\", search for **WhatsApp**, and select **Send Message**."
                    )

                    // Step 3: Configure the action
                    stepCard(
                        number: 3,
                        icon: "person.fill",
                        title: "Set recipient & message",
                        detail: configureDetail
                    )

                    // Step 4: Turn off Show When Run
                    stepCard(
                        number: 4,
                        icon: "eye.slash.fill",
                        title: "Turn off \"Show When Run\"",
                        detail: "Tap the expand arrow ▼ on the WhatsApp action, then toggle **Show When Run** OFF. This makes the send silent. Then tap **Done** to save."
                    )

                    Divider()

                    // Verify section
                    verifySection
                }
                .padding()
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

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: slot.icon)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                Text(slot.label)
                    .font(.title2.bold())
            }
            Text("Create a Shortcuts shortcut that sends your WhatsApp message automatically. This only takes a minute.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Step Card

    @ViewBuilder
    private func stepCard(
        number: Int,
        icon: String,
        title: String,
        detail: String,
        @ViewBuilder action: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Label(title, systemImage: icon)
                        .font(.headline)

                    Text(.init(detail))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            action()
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Configure Detail

    private var configureDetail: String {
        var parts: [String] = []
        if !slot.recipientName.isEmpty {
            parts.append("Set **Recipients** to **\(slot.recipientName)**")
        } else {
            parts.append("Set **Recipients** to your contact")
        }
        if !slot.messageText.isEmpty {
            parts.append("Set **Message** to: \"\(slot.messageText)\"")
        } else {
            parts.append("Type your message text")
        }
        return parts.joined(separator: "\n\n")
    }

    // MARK: - Copy & Open Button

    @ViewBuilder
    private var copyAndOpenButton: some View {
        Button {
            UIPasteboard.general.string = slot.shortcutName
            copiedName = true
            ShortcutLauncher.openShortcutsToCreate()
        } label: {
            HStack {
                Image(systemName: copiedName ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
                VStack(alignment: .leading) {
                    Text(copiedName ? "Copied! Opening Shortcuts..." : "Copy Name & Open Shortcuts")
                        .font(.subheadline.bold())
                    Text("Name: \(slot.shortcutName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.forward.app.fill")
            }
            .padding()
            .background(accentColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Verify Section

    @ViewBuilder
    private var verifySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All done? Verify it works:")
                .font(.headline)

            Button {
                verifying = true
                verifyResult = nil
                ShortcutLauncher.runShortcut(for: slotIndex)
                // Give the shortcut a moment to execute and callback
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    verifying = false
                    // Check if the slot state changed (the callback would have updated it)
                    let slots = SlotStore.shared.loadSlots()
                    if slotIndex < slots.count {
                        let state = slots[slotIndex].slotState
                        if state == .sent {
                            verifyResult = .success
                        } else if state == .failed {
                            verifyResult = .failed("Shortcut ran but failed. Check the shortcut name matches exactly: \(slot.shortcutName)")
                        } else {
                            // Still idle or sending — shortcut probably wasn't found
                            verifyResult = .failed("No response. Make sure the shortcut is named exactly: \(slot.shortcutName)")
                        }
                    }
                }
            } label: {
                HStack {
                    if verifying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    Text(verifying ? "Testing..." : "Test Shortcut")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(verifying)

            if let result = verifyResult {
                switch result {
                case .success:
                    Label("Shortcut works! You're all set.", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                case .failed(let message):
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
