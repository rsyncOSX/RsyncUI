import Foundation

class TestDataJSON {
    let urlSession = URLSession.shared
    let jsonDecoder = JSONDecoder()

    var configurationsJSON: String =
        "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/configurations.json"
    var logrecordsJSON: String =
        "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/logrecords.json"

    var configurations: [Configuration]?
    var logrecords: [LogRecords]?
    var logs: [Log]?
    var validhiddenIDs = Set<Int>()

    func getconfigurationsJSON() async throws -> [DecodeConfiguration]? {
        if let url = URL(string: configurationsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([DecodeConfiguration].self, from: data)
        } else {
            return nil
        }
    }

    func getlogrecordsJSON() async throws -> [DecodeLogRecords]? {
        if let url = URL(string: logrecordsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([DecodeLogRecords].self, from: data)
        } else {
            return nil
        }
    }

    func getconfigurations() async {
        validhiddenIDs.removeAll()
        do {
            if let data = try await getconfigurationsJSON() {
                var myconfigurations = [Configuration]()
                for i in 0 ..< data.count {
                    let oneconfiguration = Configuration(data[i])
                    myconfigurations.append(oneconfiguration)
                    validhiddenIDs.insert(oneconfiguration.hiddenID)
                }
                let sorted = myconfigurations.sorted { conf1, conf2 in
                    if let days1 = conf1.dateRun?.en_us_date_from_string(),
                       let days2 = conf2.dateRun?.en_us_date_from_string()
                    {
                        return days1 > days2
                    }
                    return false
                }
                configurations = sorted
            }
        } catch {}
    }

    func getlogrecords() async {
        do {
            if let data = try await getlogrecordsJSON() {
                var mylogrecords = [LogRecords]()
                for i in 0 ..< data.count {
                    let oneschedule = LogRecords(data[i])
                    mylogrecords.append(oneschedule)
                }
                logrecords = mylogrecords
                if mylogrecords.count > 0 {
                    var mylogs = [Log]()
                    for i in 0 ..< mylogrecords.count {
                        if let records = mylogrecords[i].logrecords {
                            mylogs.append(contentsOf: records)
                        }
                    }
                    logs = mylogs.sorted(by: \.date, using: >)
                }
            }
        } catch {}
    }
}
