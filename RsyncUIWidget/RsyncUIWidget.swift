//
//  RsyncUIWidget.swift
//  RsyncUIWidget
//
//  Created by Thomas Evensen on 10/01/2025.
//

import WidgetKit
import SwiftUI

struct RsyncUIVerifyProvider: TimelineProvider {
    func placeholder(in context: Context) -> RsyncUIStatusEntry {
        RsyncUIStatusEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RsyncUIStatusEntry) -> ()) {
        let entry = RsyncUIStatusEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 0, to: currentDate)!
        let entry = RsyncUIStatusEntry(date: entryDate)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    var url: URL? {
        if let url = URL(string: "rsyncuiapp://loadprofileandverify?profile=Pictures&id=Pictures_backup") {
            return url
        }
        return nil
    }
}

struct RsyncUIStatusEntry: TimelineEntry {
    let date: Date
    var urlstringverify: URL?
}

struct RsyncUIWidgetEntryView : View {
    var entry: RsyncUIVerifyProvider.Entry

    var body: some View {
        if let url = entry.urlstringverify {
            VStack {
                Text("Estimate: \(url)")
                Text(entry.date, style: .time)
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(Color(.yellow))
                    .widgetURL(url)
            }
        } else {
            HStack {
                Text("Estimate: no URL set")
                Text(entry.date, style: .time)
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(Color(.red))
            }
        }
    }
}

struct RsyncUIWidget: Widget {
    let kind: String = "RsyncUIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RsyncUIVerifyProvider()) { entry in
            RsyncUIWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Verify")
        .description("Verify Pictures")
    }
}

/*
struct ExecuteTaskVerify: AppIntent {
    static var title: LocalizedStringResource = "Execute Verify"
    let urlstring = URL(string: "rsyncuiapp://loadprofileandverify?profile=Pictures&id=Pictures_backup")
    
    func perform() async throws -> some IntentResult {
        print("Perform triggered")
        // NSWorkspace.shared.open(URL(string: urlstring)!)
        return .result()
    }
}

struct ExecuteTaskEstimate: AppIntent {
    static var title: LocalizedStringResource = "Estimate Task"
    // let urlstring = "https://rsyncui.netlify.app/blog/"
    
    func perform() async throws -> some IntentResult {
        print("Perform triggered")
        // NSWorkspace.shared.open(URL(string: urlstring)!)
        return .result()
    }
}
*/
