//
//  RsyncUIWidget.swift
//  RsyncUIWidget
//
//  Created by Thomas Evensen on 12/01/2025.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
  typealias Entry = SimpleEntry
  
  typealias Intent = WidgetsConfig
  
  func placeholder(in context: Context) -> SimpleEntry {
    Entry(date: Date(), emoji: "😀")
  }
  
  func snapshot(for configuration: WidgetsConfig, in context: Context) async -> Entry {
    let entry = Entry(date: Date(), emoji: "😀")
    return entry
  }
  
  func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
    var entries: [SimpleEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = Entry(date: entryDate, emoji: "😀")
      entries.append(entry)
    }
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    return timeline
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let emoji: String
}

struct WidgetsEntryView : View {
  var entry: Provider.Entry
  
  var body: some View {
    VStack {
      HStack {
        Text("Time:")
        Text(entry.date, style: .time)
      }
      
      Text("Emoji:")
      Text(entry.emoji)
    }
  }
}

struct RsyncUIWidget: Widget {
  let kind: String = "Widgets"
  
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: WidgetsConfig.self,
      provider: Provider(),
      content: { entry in
        WidgetsEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      }
    )
    .configurationDisplayName("My Widget")
    .description("This is an example widget.")
  }
}

