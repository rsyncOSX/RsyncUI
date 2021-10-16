//
//  ReadConfigurationsPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/05/2021.
//
// swiftlint:disable cyclomatic_complexity
//
// This class is used only when converting PLIST file to JSON

import Combine
import Foundation

final class ReadConfigurationsPLIST: NamesandPaths {
    var profile: String?
    var filenamedatastore = ["configRsync.plist"]
    var subscriptons = Set<AnyCancellable>()
    var configurations = [Configuration]()
    // True if PLIST data is found
    var thereisplistdata: Bool = false

    // JSON data already exists
    var jsonfileexist: Bool {
        var filename: String = ""
        if let profile = profile, let path = fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedReference.shared.fileconfigurationsjson
        } else {
            if let fullroot = fullpathmacserial {
                filename = fullroot + "/" + SharedReference.shared.fileconfigurationsjson
            }
        }
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filename)
    }

    // Write data as JSON file
    func writedatatojson() {
        _ = WriteConfigurationJSON(profile, configurations)
    }

    private func setconfigurations(_ data: [NSDictionary]) {
        for i in 0 ..< data.count {
            let dict = data[i]
            let configplist = ConfigurationPlist(dict)
            var config = Configuration()
            config.hiddenID = configplist.hiddenID
            config.task = configplist.task
            config.localCatalog = configplist.localCatalog
            config.offsiteCatalog = configplist.offsiteCatalog
            config.offsiteUsername = configplist.offsiteUsername
            config.parameter1 = configplist.parameter1
            config.parameter2 = configplist.parameter2
            config.parameter3 = configplist.parameter3
            config.parameter4 = configplist.parameter4
            config.parameter5 = configplist.parameter5
            config.parameter6 = configplist.parameter6
            config.offsiteServer = configplist.offsiteServer
            config.snapshotnum = configplist.snapshotnum
            config.snapdayoffweek = configplist.snapdayoffweek
            config.snaplast = configplist.snaplast
            config.dateRun = configplist.dateRun
            config.parameter8 = configplist.parameter8
            config.parameter9 = configplist.parameter9
            config.parameter10 = configplist.parameter10
            config.parameter11 = configplist.parameter11
            config.parameter12 = configplist.parameter12
            config.parameter13 = configplist.parameter13
            config.parameter14 = configplist.parameter14
            config.rsyncdaemon = configplist.rsyncdaemon
            config.sshport = configplist.sshport
            config.sshkeypathandidentityfile = configplist.sshkeypathandidentityfile
            config.pretask = configplist.pretask
            config.executepretask = configplist.executepretask
            config.posttask = configplist.posttask
            config.executeposttask = configplist.executeposttask
            config.haltshelltasksonerror = configplist.haltshelltasksonerror
            configurations.append(config)
        }
        if configurations.count > 0 { thereisplistdata = true }
    }

    init(_ profile: String?) {
        super.init(.configurations)
        self.profile = profile
        filenamedatastore.publisher
            .compactMap { name -> URL? in
                var filename: String = ""
                if let profile = profile, let path = fullpathmacserial {
                    filename = path + "/" + profile + "/" + name
                } else {
                    if let fullroot = fullpathmacserial {
                        filename = fullroot + "/" + name
                    }
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> NSDictionary in
                try NSDictionary(contentsOf: url, error: ())
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] data in
                if let items = data.object(forKey: "Catalogs") as? NSArray {
                    let configurations = items.map { row -> NSDictionary? in
                        switch row {
                        case is NSNull:
                            return nil
                        case let value as NSDictionary:
                            return value
                        default:
                            return nil
                        }
                    }
                    guard configurations.count > 0 else { return }
                    var data = [NSDictionary]()
                    for i in 0 ..< configurations.count {
                        if let item = configurations[i] {
                            data.append(item)
                        }
                    }
                    setconfigurations(data)
                }

                subscriptons.removeAll()
            }).store(in: &subscriptons)
    }
}
