//
//  DemoDataJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/01/2024.
//

import Foundation

class DemoDataJSON {
    let urlSession = URLSession.shared
    let jsonDecoder = JSONDecoder()

    var configurationsJSON: String =
        "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/configurations.json"
    var logrecordsJSON: String =
        "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/logrecords.json"

    private func getconfigurationsJSON() async throws -> [DecodeConfiguration]? {
        if let url = URL(string: configurationsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([DecodeConfiguration].self, from: data)
        } else {
            return nil
        }
    }

    private func getlogrecordsJSON() async throws -> [DecodeLogRecords]? {
        if let url = URL(string: logrecordsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([DecodeLogRecords].self, from: data)
        } else {
            return nil
        }
    }

    func getconfigurations() async -> [SynchronizeConfiguration]? {
        do {
            if let data = try await getconfigurationsJSON() {
                var myconfigurations = [SynchronizeConfiguration]()
                for i in 0 ..< data.count {
                    let oneconfiguration = SynchronizeConfiguration(data[i])
                    myconfigurations.append(oneconfiguration)
                }
                let sorted = myconfigurations.sorted { conf1, conf2 in
                    if let days1 = conf1.dateRun?.en_us_date_from_string(),
                       let days2 = conf2.dateRun?.en_us_date_from_string()
                    {
                        return days1 > days2
                    }
                    return false
                }
                return sorted
            }
        } catch {
            return nil
        }
        return nil
    }

    func getlogrecords() async -> [LogRecords]? {
        do {
            if let data = try await getlogrecordsJSON() {
                var mylogrecords = [LogRecords]()
                for i in 0 ..< data.count {
                    let oneschedule = LogRecords(data[i])
                    mylogrecords.append(oneschedule)
                }
                return mylogrecords
            }
        } catch {
            return nil
        }
        return nil
    }
}
