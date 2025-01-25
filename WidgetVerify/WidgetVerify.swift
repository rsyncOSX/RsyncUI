//
//  WidgetVerify.swift
//  WidgetVerify
//
//  Created by Thomas Evensen on 15/01/2025.
//

import DecodeEncodeGeneric
import Foundation
import RsyncUIDeepLinks
import SwiftUI
import WidgetKit

@MainActor
struct RsyncUIVerifyProvider: @preconcurrency TimelineProvider {
    func placeholder(in _: Context) -> RsyncUIWidgetVerifyEntry {
        if let queryelements, queryelements.queryItems?.count ?? 0 > 1 {
            RsyncUIWidgetVerifyEntry(date: Date(),
                                     urlstringverify: url,
                                     profile: queryelements.queryItems?[0].value,
                                     task: queryelements.queryItems?[1].value)
        } else {
            RsyncUIWidgetVerifyEntry(date: Date(), urlstringverify: url)
        }
    }

    func getSnapshot(in _: Context, completion: @escaping (RsyncUIWidgetVerifyEntry) -> Void) {
        if let queryelements, queryelements.queryItems?.count ?? 0 > 1 {
            let entry = RsyncUIWidgetVerifyEntry(date: Date(),
                                                 urlstringverify: url,
                                                 profile: queryelements.queryItems?[0].value,
                                                 task: queryelements.queryItems?[1].value)
            completion(entry)
        } else {
            let entry = RsyncUIWidgetVerifyEntry(date: Date(), urlstringverify: url)
            completion(entry)
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        if let queryelements, queryelements.queryItems?.count ?? 0 > 1 {
            let entry = RsyncUIWidgetVerifyEntry(date: Date(),
                                                 urlstringverify: url,
                                                 profile: queryelements.queryItems?[0].value,
                                                 task: queryelements.queryItems?[1].value)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        } else {
            let entry = RsyncUIWidgetVerifyEntry(date: entryDate, urlstringverify: url)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

    private func readconfiguration() -> String? {
        // Userconfiguration json file
        let userconfigjson = "rsyncuiconfig.json"
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

    var queryelements: URLComponents? {
        if let url {
            do {
                let queryelement = try RsyncUIDeepLinks().validateScheme(url)
                return queryelement
            } catch {
                return nil
            }
        }
        return nil
    }

    var url: URL? {
        let urlstring = readconfiguration()
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
    var profile: String?
    var task: String?
}

struct RsyncUIWidgetVerifyEntryView: View {
    var entry: RsyncUIVerifyProvider.Entry

    var body: some View {
        if let url = entry.urlstringverify,
           let profile = entry.profile,
           let task = entry.task
        {
            VStack(alignment: .leading) {
                Text("Verify")
                    .font(.title2)
                Text("Profile: \(profile)")
                Text("\(task)")
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

struct WidgetVerify: Widget {
    let kind: String = "WidgetVerify"

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
