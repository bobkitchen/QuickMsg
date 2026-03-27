import SwiftUI

struct SlotEditorView: View {
    @Binding var slot: MessageSlot
    let slotIndex: Int
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingContactPicker = false

    private let commonIcons = [
        "paperplane.fill", "bubble.left.fill", "location.fill",
        "house.fill", "building.2.fill", "car.fill",
        "clock.fill", "heart.fill", "star.fill",
        "bell.fill", "hand.wave.fill", "figure.walk",
        "cup.and.saucer.fill", "fork.knife", "bed.double.fill",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Button Appearance") {
                    TextField("Label", text: $slot.label)
                        .textInputAutocapitalization(.words)

                    iconPicker
                }

                Section("Recipient") {
                    Button(action: { showingContactPicker = true }) {
                        HStack {
                            Label("Pick Contact", systemImage: "person.crop.circle.fill")
                            Spacer()
                            if !slot.recipientName.isEmpty {
                                Text(slot.recipientName)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !slot.recipientPhone.isEmpty {
                        HStack {
                            Text("Phone")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(slot.recipientPhone)
                                .font(.footnote.monospaced())
                        }
                    }
                }

                Section("Message") {
                    TextEditor(text: $slot.messageText)
                        .frame(minHeight: 80)
                }

                Section {
                    Toggle("Enabled", isOn: $slot.isEnabled)
                }
            }
            .navigationTitle("Slot \(slotIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(!slot.isConfigured)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(
                    recipientName: $slot.recipientName,
                    recipientPhone: $slot.recipientPhone
                )
            }
        }
    }

    @ViewBuilder
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(commonIcons, id: \.self) { iconName in
                    Button {
                        slot.icon = iconName
                    } label: {
                        Image(systemName: iconName)
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(slot.icon == iconName ? accentColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(slot.icon == iconName ? accentColor : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var accentColor: Color {
        let c = AppConstants.slotColors[slotIndex % AppConstants.slotColors.count]
        return Color(red: c.red, green: c.green, blue: c.blue)
    }
}
