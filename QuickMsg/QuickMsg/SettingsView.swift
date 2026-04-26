import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var workerURL: String = ""
    @State private var workerSecret: String = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://lango-worker.your-account.workers.dev",
                              text: $workerURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Worker URL")
                } footer: {
                    Text("The Cloudflare Worker that authenticates this device and forwards to Meta WhatsApp. URL is stored in App Group UserDefaults.")
                }

                Section {
                    SecureField("Shared secret", text: $workerSecret)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Worker Secret")
                } footer: {
                    Text("Stored in the iOS Keychain (after-first-unlock-this-device-only) and shared with the widget extension via Keychain Access Group. Never leaves the device except as the X-Lango-Secret header on Worker calls.")
                }

                Section {
                    safetyChecklist
                } header: {
                    Text("Driver-safety checklist")
                } footer: {
                    Text("These iPhone Settings are required for Lango to fire while the phone is locked in your pocket. iOS occasionally resets \"Allow Siri When Locked\" — re-check after major updates.")
                }

                if let saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                workerURL = AppConfig.workerURL
                workerSecret = AppConfig.workerSecret
            }
        }
    }

    private var safetyChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            checklistRow("Settings → Siri → Listen for \u{201C}Hey Siri\u{201D}: ON")
            checklistRow("Settings → Siri → Allow Siri When Locked: ON")
            checklistRow("Settings → Siri → Press Side Button for Siri: ON")
        }
        .font(.footnote)
    }

    private func checklistRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
            Text(text)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func save() {
        AppConfig.workerURL = workerURL
        do {
            try AppConfig.setWorkerSecret(workerSecret)
            dismiss()
        } catch {
            saveError = "Failed to save secret: \(error)"
        }
    }
}
