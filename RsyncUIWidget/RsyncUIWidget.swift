//
//  RsyncUIWidget.swift
//  RsyncUIWidget
//
//  Created by Thomas Evensen on 10/01/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

struct RsyncUIProvider: TimelineProvider {
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
}

struct RsyncUIStatusEntry: TimelineEntry {
    let date: Date
}

struct RsyncUIWidgetEntryView : View {
    var entry: RsyncUIProvider.Entry
    let urlstringverify = URL(string: "rsyncuiapp://loadprofileandverify?profile=Pictures&id=Pictures_backup")
    let urlstringestimate = URL(string: "rsyncuiapp://loadprofileandestimate?profile=default")

    var body: some View {
        HStack {
            Text("Verify:")
            Text(entry.date, style: .time)
            Image(systemName: "play.fill")
                .foregroundColor(.blue)
                .widgetURL(urlstringverify)
        }
    }
}

struct RsyncUIWidget: Widget {
    let kind: String = "RsyncUIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RsyncUIProvider()) { entry in
            RsyncUIWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
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
