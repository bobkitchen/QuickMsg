import WidgetKit
import SwiftUI

struct QuickMsgEntry: TimelineEntry {
    let date: Date
    let slots: [MessageSlot]
}

struct QuickMsgTimelineProvider: TimelineProvider {
    private let store = SlotStore()

    func placeholder(in context: Context) -> QuickMsgEntry {
        QuickMsgEntry(date: .now, slots: (0..<3).map { MessageSlot(slotIndex: $0) })
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickMsgEntry) -> Void) {
        store.resetExpiredStates()
        let slots = store.loadSlots()
        completion(QuickMsgEntry(date: .now, slots: slots))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickMsgEntry>) -> Void) {
        store.resetExpiredStates()
        let slots = store.loadSlots()
        let entry = QuickMsgEntry(date: .now, slots: slots)

        // Schedule a refresh for when any feedback state should expire
        var nextRefresh = Date().addingTimeInterval(60 * 15) // Default: 15 min
        for slot in slots {
            if let ts = slot.stateTimestamp,
               (slot.slotState == .sent || slot.slotState == .failed || slot.slotState == .sending) {
                let expiry = ts.addingTimeInterval(AppConstants.feedbackDisplayDuration)
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
struct QuickMsgWidgetBundle: Widget {
    let kind = AppConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickMsgTimelineProvider()) { entry in
            QuickMsgWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("QuickMsg")
        .description("Send preset WhatsApp messages with one tap.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}
