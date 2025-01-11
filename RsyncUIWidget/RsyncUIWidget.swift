//
//  RsyncUIWidget.swift
//  RsyncUIWidget
//
//  Created by Thomas Evensen on 10/01/2025.
//

import WidgetKit
import SwiftUI

struct RsyncUIProvider: TimelineProvider {
    func placeholder(in context: Context) -> RsyncUIStatusEntry {
        RsyncUIStatusEntry(date: Date(), rsyncuistatus: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (RsyncUIStatusEntry) -> ()) {
        let entry = RsyncUIStatusEntry(date: Date(), rsyncuistatus: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let entry = RsyncUIStatusEntry(date: entryDate, rsyncuistatus: "😀")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct RsyncUIStatusEntry: TimelineEntry {
    let date: Date
    let rsyncuistatus: String
}

struct RsyncUIWidgetEntryView : View {
    var entry: RsyncUIProvider.Entry

    var body: some View {
        VStack {
            
            Button("Test") {}
            
            HStack {
                Text("Time:")
                Text(entry.date, style: .time)
            }

            HStack {
                Text("RsyncUI status:")
                Text(entry.rsyncuistatus)
            }
        }
    }
    
    var profilenames: WidgetProfilenames {
        WidgetProfilenames()
    }
}

struct RsyncUIWidget: Widget {
    let kind: String = "RsyncUIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RsyncUIProvider()) { entry in
            if #available(macOS 14.0, *) {
                RsyncUIWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                RsyncUIWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}
