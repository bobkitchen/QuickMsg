import SwiftUI
import WidgetKit
import AppIntents

struct QuickMsgWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: QuickMsgEntry

    var body: some View {
        switch family {
        case .systemSmall:
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

// MARK: - System Small (also used on CarPlay)
// On CarPlay, systemSmall is the only supported family.
// Layout uses large tap targets and system fonts for car-screen legibility.

private struct SmallWidgetView: View {
    @Environment(\.widgetContentMargins) var margins
    let slots: [MessageSlot]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                SlotButton(slot: slot, index: index, compact: true)
            }
        }
    }
}

// MARK: - System Medium (iPhone only — more room for labels)

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
        let c = AppConstants.slotColors[index % AppConstants.slotColors.count]
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

    // Compact: stacked icon + short label (systemSmall / CarPlay)
    // Uses large tap targets — entire row is tappable
    private var compactLayout: some View {
        HStack(spacing: 8) {
            stateIcon
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 28, height: 28)

            Text(slot.label)
                .font(.system(.subheadline, weight: .semibold))
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

    // Wide: icon + label + recipient name (systemMedium)
    private var wideLayout: some View {
        VStack(spacing: 4) {
            stateIcon
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 32, height: 32)

            Text(slot.label)
                .font(.system(.caption, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if !slot.recipientName.isEmpty {
                Text(slot.recipientName)
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
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

// MARK: - Accessory Circular (Lock Screen — icon only)

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

// MARK: - Accessory Rectangular (Lock Screen — icon + label)

private struct AccessoryRectangularView: View {
    let slot: MessageSlot

    var body: some View {
        Button(intent: SendMessageIntent(slotIndex: slot.slotIndex ?? 0)) {
            HStack(spacing: 8) {
                Image(systemName: slot.isConfigured ? slot.icon : "questionmark")
                    .font(.system(size: 16, weight: .semibold))

                VStack(alignment: .leading, spacing: 1) {
                    Text(slot.label)
                        .font(.system(.headline))
                        .lineLimit(1)
                    if !slot.recipientName.isEmpty {
                        Text(slot.recipientName)
                            .font(.system(.caption))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .disabled(!slot.isConfigured)
    }
}
