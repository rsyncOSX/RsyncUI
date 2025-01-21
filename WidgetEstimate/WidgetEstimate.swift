import DecodeEncodeGeneric
import Foundation
import RsyncUIDeepLinks
import SwiftUI
import WidgetKit

@MainActor
struct RsyncUIEstimateProvider: @preconcurrency TimelineProvider {
    func placeholder(in _: Context) -> RsyncUIWidgetEstimateEntry {
        if let queryelements, queryelements.queryItems?.count ?? 0 > 0 {
            RsyncUIWidgetEstimateEntry(date: Date(),
                                       urlstringestimate: url,
                                       profile: queryelements.queryItems?[0].value)
        } else {
            RsyncUIWidgetEstimateEntry(date: Date(), urlstringestimate: url)
        }
    }

    func getSnapshot(in _: Context, completion: @escaping (RsyncUIWidgetEstimateEntry) -> Void) {
        if let queryelements, queryelements.queryItems?.count ?? 0 > 0 {
            let entry = RsyncUIWidgetEstimateEntry(date: Date(),
                                                   urlstringestimate: url,
                                                   profile: queryelements.queryItems?[0].value)
            completion(entry)
        } else {
            let entry = RsyncUIWidgetEstimateEntry(date: Date(), urlstringestimate: url)
            completion(entry)
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        if let queryelements, queryelements.queryItems?.count ?? 0 > 0 {
            let entry = RsyncUIWidgetEstimateEntry(date: Date(),
                                                   urlstringestimate: url,
                                                   profile: queryelements.queryItems?[0].value)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        } else {
            let entry = RsyncUIWidgetEstimateEntry(date: entryDate, urlstringestimate: url)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

    private func readuserconfiguration() -> String? {
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
                decodeuserconfiguration.decodestringdatafileURL(DecodeStringEstimate.self,
                                                                fromwhere: userconfigurationfile)
            {
                return importeddata.urlstringestimate
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
}

struct RsyncUIWidgetEstimateEntry: TimelineEntry {
    let date: Date
    var urlstringestimate: URL?
    var profile: String?
}

struct RsyncUIWidgetEstimateEntryView: View {
    var entry: RsyncUIEstimateProvider.Entry

    var body: some View {
        if let url = entry.urlstringestimate,
           let profile = entry.profile
        {
            VStack {
                Text("Estimate profile: \(profile)")
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

struct WidgetEstimate: Widget {
    let kind: String = "WidgetEstimate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RsyncUIEstimateProvider()) { entry in
            RsyncUIWidgetEstimateEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Estimate")
        .description("Estimate & Synchronize your files.")
    }
}

struct DecodeStringEstimate: Codable {
    let urlstringestimate: String?

    enum CodingKeys: String, CodingKey {
        case urlstringestimate
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        urlstringestimate = try values.decodeIfPresent(String.self, forKey: .urlstringestimate)
    }
}
