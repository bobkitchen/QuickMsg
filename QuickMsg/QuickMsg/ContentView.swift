import AppIntents
import SwiftUI
import WidgetKit

enum ActiveSheet: Identifiable {
    case editor(Int)
    case settings

    var id: String {
        switch self {
        case .editor(let i): return "editor-\(i)"
        case .settings: return "settings"
        }
    }
}

struct ContentView: View {
    @State private var slots: [MessageSlot] = []
    @State private var activeSheet: ActiveSheet?
    @State private var lastSendError: String?

    private let store = SlotStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusBanner
                }

                ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                    Section {
                        SlotCardView(
                            slot: slot,
                            index: index,
                            onEdit: { activeSheet = .editor(index) },
                            onTest: { Task { await testSlot(index) } }
                        )
                    }
                }

                if let lastSendError {
                    Section {
                        Label(lastSendError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Lango")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .onAppear { loadSlots() }
            .sheet(item: $activeSheet, onDismiss: { loadSlots() }) { sheet in
                switch sheet {
                case .editor(let index):
                    SlotEditorView(
                        slot: binding(for: index),
                        slotIndex: index,
                        onSave: { saveSlot(at: index) }
                    )
                case .settings:
                    SettingsView()
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        let configured = slots.filter(\.isConfigured).count
        let workerReady = AppConfig.isConfigured

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: workerReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(workerReady ? .green : .orange)
                Text(workerReady ? "Worker configured" : "Worker not configured — open Settings")
                    .font(.subheadline)
                Spacer()
            }
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.secondary)
                Text("\(configured)/\(slots.count) slots configured")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    private func loadSlots() {
        slots = store.loadSlots()
    }

    private func binding(for index: Int) -> Binding<MessageSlot> {
        Binding(
            get: { slots[index] },
            set: { slots[index] = $0 }
        )
    }

    private func saveSlot(at index: Int) {
        store.updateSlot(at: index) { slot in
            slot = slots[index]
        }
        LangoShortcuts.updateAppShortcutParameters()
        WidgetCenter.shared.reloadTimelines(ofKind: LangoConstants.widgetKind)
    }

    @MainActor
    private func testSlot(_ index: Int) async {
        let slot = slots[index]
        guard slot.isConfigured else { return }
        guard AppConfig.isConfigured else {
            lastSendError = "Configure the Worker URL and secret in Settings first."
            return
        }

        lastSendError = nil
        store.setSlotState(index, state: .sending)
        loadSlots()

        do {
            try await MessageService.send(messageKey: slot.messageKey)
            store.setSlotState(index, state: .sent)
        } catch {
            store.setSlotState(index, state: .failed)
            lastSendError = "\(error)"
        }
        loadSlots()
    }
}

// MARK: - Slot Card

private struct SlotCardView: View {
    let slot: MessageSlot
    let index: Int
    let onEdit: () -> Void
    let onTest: () -> Void

    private var accentColor: Color {
        let c = LangoConstants.slotColors[index % LangoConstants.slotColors.count]
        return Color(red: c.red, green: c.green, blue: c.blue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: slot.icon)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                Text(slot.label)
                    .font(.headline)
                Spacer()
                statusBadge
            }

            if slot.isConfigured {
                HStack(spacing: 6) {
                    Text("messageKey:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(slot.messageKey)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                if let lastSent = slot.lastSentAt {
                    Text("Last sent: \(lastSent.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    Button("Edit", action: onEdit)
                    Spacer()
                    Button("Test send", action: onTest)
                        .tint(.green)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button(action: onEdit) {
                    Label("Configure this slot", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(accentColor)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch slot.slotState {
        case .idle:
            if slot.isConfigured {
                badge("Ready", color: .green)
            } else {
                badge("Not Set Up", color: .secondary)
            }
        case .sending:
            badge("Sending…", color: .orange)
        case .sent:
            badge("Sent", color: .green)
        case .failed:
            badge("Failed", color: .red)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
    }
}
