//
//  RsyncUIWidgetVerify.swift
//  RsyncUIWidgetVerify
//
//  Created by Thomas Evensen on 14/01/2025.
//

import WidgetKit
import SwiftUI
import DecodeEncodeGeneric
import Foundation

@MainActor
struct RsyncUIVerifyProvider: @preconcurrency TimelineProvider {
    func placeholder(in context: Context) -> RsyncUIWidgetVerifyEntry {
        RsyncUIWidgetVerifyEntry(date: Date(), urlstringverify: url)
     }

     func getSnapshot(in context: Context, completion: @escaping (RsyncUIWidgetVerifyEntry) -> ()) {
         let entry = RsyncUIWidgetVerifyEntry(date: Date(), urlstringverify: url)
         completion(entry)
     }

     func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
         let currentDate = Date()
         let entryDate = Calendar.current.date(byAdding: .minute, value: 0, to: currentDate)!
         let entry = RsyncUIWidgetVerifyEntry(date: entryDate, urlstringverify: url)
         let timeline = Timeline(entries: [entry], policy: .atEnd)
         completion(timeline)
     }
     
     private func readuserconfiguration() -> String? {
         // Userconfiguration json file
         let userconfigjson: String = "rsyncuiconfig.json"
         let decodeuserconfiguration = DecodeGeneric()
         var userconfigurationfile = ""
         if let path = documentscatalog {
             userconfigurationfile = path + "/" + userconfigjson
             print(userconfigurationfile)
         } else {
             return nil
         }
         do {
             if let importeddata = try
                 decodeuserconfiguration.decodestringdatafileURL(DecodeStringVerify.self,
                                                                 fromwhere: userconfigurationfile)
             {
                 return importeddata.urlstringverify
             }

         } catch {
             return nil
         }
         return nil
     }
     
     var documentscatalog: String? {
         let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
         return paths.firstObject as? String
     }
     
     var url: URL? {
         let urlstring = readuserconfiguration()
         guard let urlstring, urlstring.isEmpty == false else { return nil }
         if let url = URL(string: urlstring) {
             return url
         }
         return nil
     }
}

struct RsyncUIWidgetVerifyEntry: TimelineEntry {
    let date: Date
    var urlstringverify: URL?
}

struct RsyncUIWidgetVerifyEntryView : View {
    var entry: RsyncUIVerifyProvider.Entry

    var body: some View {
        if let url = entry.urlstringverify {
            VStack {
                Text("Verify: \(url)")
                HStack {
                    Text(entry.date, style: .time)
                    Image(systemName: "bolt.shield")
                        .foregroundColor(Color(.yellow))
                        .widgetURL(url)
                }
                
            }
        } else {
            HStack {
                Text("Verify: no URL set")
                HStack {
                    Text(entry.date, style: .time)
                    Image(systemName: "bolt.shield")
                        .foregroundColor(Color(.red))
                }
            }
        }
    }
}

struct RsyncUIWidgetVerify: Widget {
    let kind: String = "RsyncUIWidgetVerify"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RsyncUIVerifyProvider()) { entry in
            RsyncUIWidgetVerifyEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Verify")
        .description("Verify task.")
    }
}

struct DecodeStringVerify: Codable {
    let urlstringverify: String?

    enum CodingKeys: String, CodingKey {
        case urlstringverify
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        urlstringverify = try values.decodeIfPresent(String.self, forKey: .urlstringverify)
    }
}
