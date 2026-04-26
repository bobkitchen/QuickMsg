import SwiftUI
import WidgetKit
import AppIntents

struct LangoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LangoEntry

    var body: some View {
        switch family {
        case .systemSmall:
            // systemSmall renders on both Home Screen and CarPlay. On CarPlay
            // the widget background is stripped (StandBy style); the layout
            // below is high-contrast and legible without a background.
            SmallWidgetView(slots: entry.slots)
        case .systemMedium:
            MediumWidgetView(slots: entry.slots)
        case .accessoryCircular:
            AccessoryCircularView(slot: entry.slots.first ?? MessageSlot(slotIndex: 0))
        case .accessoryRectangular:
            AccessoryRectangularView(slot: entry.slots.first ?? MessageSlot(slotIndex: 0))
        default:
            SmallWidgetView(slots: entry.slots)
        }
    }
}

// MARK: - System Small (Home Screen + CarPlay)

private struct SmallWidgetView: View {
    let slots: [MessageSlot]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                SlotButton(slot: slot, index: index, compact: true)
            }
        }
    }
}

// MARK: - System Medium (Home Screen only — not rendered on CarPlay)

private struct MediumWidgetView: View {
    let slots: [MessageSlot]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                SlotButton(slot: slot, index: index, compact: false)
            }
        }
        .padding(4)
    }
}

// MARK: - Slot Button

private struct SlotButton: View {
    let slot: MessageSlot
    let index: Int
    let compact: Bool

    private var accentColor: Color {
        let c = LangoConstants.slotColors[index % LangoConstants.slotColors.count]
        return Color(red: c.red, green: c.green, blue: c.blue)
    }

    var body: some View {
        Button(intent: SendMessageIntent(slotIndex: index)) {
            if compact {
                compactLayout
            } else {
                wideLayout
            }
        }
        .buttonStyle(.plain)
        .disabled(!slot.isConfigured || slot.slotState == .sending)
    }

    // Compact: row with state icon + label. Used at systemSmall (Home + CarPlay).
    // No decorative background colour — CarPlay strips backgrounds, so contrast
    // comes from the icon and bold label.
    private var compactLayout: some View {
        HStack(spacing: 8) {
            stateIcon
                .font(.system(size: 22, weight: .bold))
                .frame(width: 30, height: 30)

            Text(slot.label)
                .font(.system(.subheadline, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundForState)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // Wide: stacked icon + label. Home Screen only.
    private var wideLayout: some View {
        VStack(spacing: 4) {
            stateIcon
                .font(.system(size: 26, weight: .bold))
                .frame(width: 36, height: 36)

            Text(slot.label)
                .font(.system(.caption, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(backgroundForState)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch slot.slotState {
        case .idle:
            Image(systemName: slot.icon)
                .foregroundStyle(slot.isConfigured ? accentColor : .secondary)
        case .sending:
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)
        case .sent:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private var backgroundForState: some ShapeStyle {
        switch slot.slotState {
        case .idle:
            return slot.isConfigured ? accentColor.opacity(0.15) : Color.secondary.opacity(0.1)
        case .sending:
            return Color.orange.opacity(0.15)
        case .sent:
            return Color.green.opacity(0.15)
        case .failed:
            return Color.red.opacity(0.15)
        }
    }
}

// MARK: - Accessory Circular (Lock Screen — non-driving surface)

private struct AccessoryCircularView: View {
    let slot: MessageSlot

    var body: some View {
        Button(intent: SendMessageIntent(slotIndex: slot.slotIndex ?? 0)) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: slot.isConfigured ? slot.icon : "questionmark")
                    .font(.system(size: 20, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
        .disabled(!slot.isConfigured)
    }
}

// MARK: - Accessory Rectangular (Lock Screen — non-driving surface)

private struct AccessoryRectangularView: View {
    let slot: MessageSlot

    var body: some View {
        Button(intent: SendMessageIntent(slotIndex: slot.slotIndex ?? 0)) {
            HStack(spacing: 8) {
                Image(systemName: slot.isConfigured ? slot.icon : "questionmark")
                    .font(.system(size: 16, weight: .semibold))

                Text(slot.label)
                    .font(.system(.headline))
                    .lineLimit(1)

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .disabled(!slot.isConfigured)
    }
}
