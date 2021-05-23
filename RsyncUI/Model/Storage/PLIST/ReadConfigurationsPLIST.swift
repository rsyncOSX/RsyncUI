//
//  ReadConfigurationsPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/05/2021.
//
// swiftlint:disable cyclomatic_complexity

import Combine
import Foundation

final class ReadConfigurationsPLIST: NamesandPaths {
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
            config = configplist.map
            
            config.profile = nil
            configurations.append(config)
        }
        if configurations.count > 0 { thereisplistdata = true }
    }

    override init(_ profile: String?) {
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
