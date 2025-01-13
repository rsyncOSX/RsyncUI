//
//  RsyncUIWidgetEstimate.swift
//  RsyncUIWidgetEstimate
//
//  Created by Thomas Evensen on 13/01/2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RsyncUIWidgetEstimateEntry {
        RsyncUIWidgetEstimateEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RsyncUIWidgetEstimateEntry) -> ()) {
        let entry = RsyncUIWidgetEstimateEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 0, to: currentDate)!
        let entry = RsyncUIWidgetEstimateEntry(date: entryDate)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct RsyncUIWidgetEstimateEntry: TimelineEntry {
    let date: Date
}

struct RsyncUIWidgetEstimateEntryView : View {
    var entry: Provider.Entry
    let urlstringestimate = URL(string: "rsyncuiapp://loadprofileandestimate?profile=default")

    var body: some View {
        HStack {
            Text("Estimate:")
            Text(entry.date, style: .time)
            Image(systemName: "bolt.shield.fill")
                .foregroundColor(Color(.yellow))
                .widgetURL(urlstringestimate)
        }
    }
}

struct RsyncUIWidgetEstimate: Widget {
    let kind: String = "RsyncUIWidgetEstimate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RsyncUIWidgetEstimateEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Estimate")
        .description("Estimate & Synchronize your files.")
    }
}
