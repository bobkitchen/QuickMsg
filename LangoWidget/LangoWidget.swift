import WidgetKit
import SwiftUI

struct LangoEntry: TimelineEntry {
    let date: Date
    let slots: [MessageSlot]
}

struct LangoTimelineProvider: TimelineProvider {
    private let store = SlotStore()

    func placeholder(in context: Context) -> LangoEntry {
        LangoEntry(date: .now, slots: (0..<LangoConstants.slotCount).map { MessageSlot(slotIndex: $0) })
    }

    func getSnapshot(in context: Context, completion: @escaping (LangoEntry) -> Void) {
        store.resetExpiredStates()
        let slots = store.loadSlots()
        completion(LangoEntry(date: .now, slots: slots))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LangoEntry>) -> Void) {
        store.resetExpiredStates()
        let slots = store.loadSlots()
        let entry = LangoEntry(date: .now, slots: slots)

        // Refresh when any feedback state should expire.
        var nextRefresh = Date().addingTimeInterval(60 * 15)
        for slot in slots {
            if let ts = slot.stateTimestamp,
               (slot.slotState == .sent || slot.slotState == .failed || slot.slotState == .sending) {
                let expiry = ts.addingTimeInterval(LangoConstants.feedbackDisplayDuration)
                if expiry < nextRefresh {
                    nextRefresh = expiry
                }
            }
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }
}

@main
struct LangoWidgetBundle: Widget {
    let kind = LangoConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LangoTimelineProvider()) { entry in
            LangoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Lango")
        .description("Send a preset WhatsApp message with one tap or one Siri phrase.")
        // systemSmall is rendered on both Home Screen and CarPlay (StandBy-style).
        // systemMedium is Home Screen only — CarPlay does not render it.
        // Lock Screen accessory families are available for non-driving use only;
        // iOS may prompt for unlock when tapped, regardless of authenticationPolicy.
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
        ])
        .contentMarginsDisabled()
    }
}
