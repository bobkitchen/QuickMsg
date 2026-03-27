import AppIntents
import SwiftUI
import WidgetKit

enum ActiveSheet: Identifiable {
    case editor(Int)

    var id: String {
        switch self {
        case .editor(let i): return "editor-\(i)"
        }
    }
}

struct ContentView: View {
    @State private var slots: [MessageSlot] = []
    @State private var activeSheet: ActiveSheet?

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
                            onTest: { testSlot(index) }
                        )
                    }
                }
            }
            .navigationTitle("QuickMsg")
            .onAppear { loadSlots() }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .editor(let index):
                    SlotEditorView(
                        slot: binding(for: index),
                        slotIndex: index,
                        onSave: { saveSlot(at: index) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        let configured = slots.filter(\.isConfigured).count
        HStack {
            Image(systemName: configured == slots.count ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(configured == slots.count ? .green : .orange)
            Text("\(configured)/\(slots.count) slots configured")
                .font(.subheadline)
            Spacer()
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
        QuickMsgShortcuts.updateAppShortcutParameters()
        WidgetCenter.shared.reloadTimelines(ofKind: AppConstants.widgetKind)
    }

    private func testSlot(_ index: Int) {
        ShortcutLauncher.runShortcut(for: index)
    }
}

// MARK: - Slot Card

private struct SlotCardView: View {
    let slot: MessageSlot
    let index: Int
    let onEdit: () -> Void
    let onTest: () -> Void

    private var accentColor: Color {
        let c = AppConstants.slotColors[index % AppConstants.slotColors.count]
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
                VStack(alignment: .leading, spacing: 4) {
                    Label(slot.recipientName, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(slot.messageText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let lastSent = slot.lastSentAt {
                    Text("Last sent: \(lastSent.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    Button("Edit", action: onEdit)
                    Spacer()
                    Button("Test", action: onTest)
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
        if slot.isConfigured {
            Text("Ready")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.green.opacity(0.2))
                .clipShape(Capsule())
        } else {
            Text("Not Set Up")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
    }
}
