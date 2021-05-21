//
//  ReadConfigurationsPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/05/2021.
//

import Combine
import Foundation

final class ReadConfigurationsPLIST: NamesandPaths {
    var filenamedatastore = ["/configRsync.plist"]
    var subscriptons = Set<AnyCancellable>()
    var configurations = [Configuration]()

    func readconfigurationsplist(_ data: [NSDictionary]) {
        for i in 0 ..< data.count {
            let dict = data[i]
            var config = Configuration(dictionary: dict)
            config.profile = profile
        }
    }

    init() {
        super.init(.configurations)
        filenamedatastore.publisher
            .compactMap { name -> URL? in
                URL(fileURLWithPath: (fullpathmacserial ?? "") + name)
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
                }
                subscriptons.removeAll()
            }).store(in: &subscriptons)
    }
}
