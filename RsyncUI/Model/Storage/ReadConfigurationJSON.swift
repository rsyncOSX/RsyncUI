//
//  ReadConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Files
import Foundation

class ReadConfigurationJSON: NamesandPaths {
    var configurations: [Configuration]?
    var filenamedatastore = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()
    var validhiddenIDs = Set<Int>()

    func setuniqueserversandlogins() -> [UniqueserversandLogins]? {
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

    override init(_ profile: String?) {
        super.init(.configurations)
        self.profile = profile
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL? in
                var filename: String = ""
                if let profile = profile, let fullroot = fullpathmacserial {
                    filename = fullroot + "/" + profile + "/" + filenamejson
                } else {
                    if let fullroot = fullpathmacserial {
                        filename = fullroot + "/" + filenamejson
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
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
                // print("completion with \(completion)")
            } receiveValue: { [unowned self] data in
                var configurations = [Configuration]()
                for i in 0 ..< data.count {
                    let transformed = TransformConfigfromJSON().transform(data[i])
                    // Validate leag sync task
                    if SharedReference.shared.synctasks.contains(transformed.task) {
                        if validhiddenIDs.contains(transformed.hiddenID) == false {
                            configurations.append(transformed)
                            // Create set of validated hidden IDs, used when
                            // loading schedules and logs
                            validhiddenIDs.insert(transformed.hiddenID)
                        }
                    }
                }
                self.configurations = configurations
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
