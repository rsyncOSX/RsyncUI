//
//  RsyncUIWidgetEstimate.swift
//  RsyncUIWidgetEstimate
//
//  Created by Thomas Evensen on 13/01/2025.
//

import WidgetKit
import SwiftUI

struct RsyncUIEstimateProvider: TimelineProvider {
    func placeholder(in context: Context) -> RsyncUIWidgetEstimateEntry {
        RsyncUIWidgetEstimateEntry(date: Date(), urlstringestimate: url)
    }

    func getSnapshot(in context: Context, completion: @escaping (RsyncUIWidgetEstimateEntry) -> ()) {
        let entry = RsyncUIWidgetEstimateEntry(date: Date(), urlstringestimate: url)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 0, to: currentDate)!
        let entry = RsyncUIWidgetEstimateEntry(date: entryDate, urlstringestimate: url)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    var url: URL? {
        if let url = URL(string: "rsyncuiapp://loadprofileandestimate?profile=default") {
            return url
        }
        return nil
    }
}

struct RsyncUIWidgetEstimateEntry: TimelineEntry {
    let date: Date
    var urlstringestimate: URL?
}

struct RsyncUIWidgetEstimateEntryView : View {
    var entry: RsyncUIEstimateProvider.Entry

    var body: some View {
        if let url = entry.urlstringestimate {
            VStack {
                Text("Estimate: \(url)")
                HStack {
                    Text(entry.date, style: .time)
                    Image(systemName: "bolt.shield.fill")
                        .foregroundColor(Color(.yellow))
                        .widgetURL(url)
                }
                
            }
        } else {
            HStack {
                Text("Estimate: no URL set")
                HStack {
                    Text(entry.date, style: .time)
                    Image(systemName: "bolt.shield.fill")
                        .foregroundColor(Color(.red))
                }
            }
        }
    }
}

struct RsyncUIWidgetEstimate: Widget {
    let kind: String = "RsyncUIWidgetEstimate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RsyncUIEstimateProvider()) { entry in
            RsyncUIWidgetEstimateEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Estimate")
        .description("Estimate & Synchronize your files.")
    }
}
