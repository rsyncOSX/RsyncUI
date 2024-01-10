//
//  ReadConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Foundation
import OSLog

class ReadConfigurationJSON: NamesandPaths {
    var configurations: [Configuration]?
    var filenamedatastore = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()
    var validhiddenIDs = Set<Int>()

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    private func failurereadlogrecords(_ profile: String?, _ validhiddenID: Set<Int>) {
        if var atpath = fullpathmacserial {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "") + "/" + SharedReference.shared.fileschedulesjson
                } else {
                    atpath += "/" + SharedReference.shared.fileschedulesjson
                }
                let exists = try validatepath(atpath)
                if exists {
                    Logger.process.info("ReadLogRecordsJSON: Copy old file for log records and save to new file")
                    _ = ReadLogrecordsOldName(profile, validhiddenID)
                }
            } catch _ {
                Logger.process.info("ReadLogRecordsJSON: Creating DEFAULT file for log records")
                var defaultlogrecords = [LogRecords()]
                guard defaultlogrecords.count == 1 else { return }
                defaultlogrecords[0].dateStart = Date().en_us_string_from_date()
                defaultlogrecords[0].profilename = profile
                WriteLogRecordsJSON(profile, defaultlogrecords)
            }
        }
    }

    private func createdefaultfileconfigurations(_ profile: String?) {
        // No file, write new file with default values
        Logger.process.info("ReadConfigurationJSON - \(profile ?? "default profile", privacy: .public): Creating default file for Configurations")
        var defaultconfiguration = [Configuration()]
        WriteConfigurationJSON(profile, defaultconfiguration)
    }

    func getuniqueserversandlogins() -> [UniqueserversandLogins]? {
        let configs = configurations?.filter {
            SharedReference.shared.synctasks.contains($0.task)
        }
        guard configs?.count ?? 0 > 0 else { return nil }
        var uniqueserversandlogins = [UniqueserversandLogins]()
        for i in 0 ..< (configs?.count ?? 0) {
            if let config = configs?[i] {
                if config.offsiteUsername.isEmpty == false, config.offsiteServer.isEmpty == false {
                    let record = UniqueserversandLogins(config.offsiteUsername, config.offsiteServer)
                    if uniqueserversandlogins.filter({ ($0.offsiteUsername == record.offsiteUsername) &&
                            ($0.offsiteServer == record.offsiteServer)
                    }).count == 0 {
                        uniqueserversandlogins.append(record)
                    }
                }
            }
        }
        return uniqueserversandlogins
    }

    init(_ profile: String?) {
        super.init(.configurations)
        // print("ReadConfigurationJSON")
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename = ""
                if let profile = profile, let path = fullpathmacserial {
                    filename = path + "/" + profile + "/" + filenamejson
                } else {
                    if let path = fullpathmacserial {
                        filename = path + "/" + filenamejson
                    }
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [DecodeConfiguration].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    self.createdefaultfileconfigurations(profile)
                    // Mark first time used, only for default profile
                    if profile == nil {
                        SharedReference.shared.firsttime = true
                    }
                }
            } receiveValue: { [unowned self] data in
                var configurations = [Configuration]()
                for i in 0 ..< data.count {
                    var configuration = Configuration(data[i])
                    configuration.profile = profile
                    // Validate sync task
                    if SharedReference.shared.synctasks.contains(configuration.task) {
                        if validhiddenIDs.contains(configuration.hiddenID) == false {
                            configurations.append(configuration)
                            // Create set of validated hidden IDs, used when
                            // loading logrecords
                            validhiddenIDs.insert(configuration.hiddenID)
                        }
                    }
                }
                let sorted = configurations.sorted { conf1, conf2 in
                    if let days1 = conf1.dateRun?.en_us_date_from_string(),
                       let days2 = conf2.dateRun?.en_us_date_from_string()
                    {
                        return days1 > days2
                    }
                    return false
                }
                self.configurations = sorted
                subscriptons.removeAll()
                Logger.process.info("ReadConfigurationJSON: read configurations from permanent storage")
            }.store(in: &subscriptons)
    }
}
