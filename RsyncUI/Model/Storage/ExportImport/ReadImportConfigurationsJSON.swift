//
//  ReadImportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/07/2024.
//
// swiftlint:disable line_length

import Combine
import Foundation
import OSLog

@MainActor
final class ReadImportConfigurationsJSON {
    var configurations: [SynchronizeConfiguration]?
    var filenamedatastore = [String]()
    var subscriptons = Set<AnyCancellable>()

    init(_ filenameimport: String) {
        filenamedatastore.append(filenameimport)
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                return URL(fileURLWithPath: filenamejson)
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
                    return
                }
            } receiveValue: { [unowned self] data in
                var configurations = [SynchronizeConfiguration]()
                for i in 0 ..< data.count {
                    let configuration = SynchronizeConfiguration(data[i])
                    configurations.append(configuration)
                }
                self.configurations = configurations
                subscriptons.removeAll()
                Logger.process.info("ReadImportConfigurationsJSON - \(filenameimport, privacy: .public): read configurations from permanent storage")
            }.store(in: &subscriptons)
    }
}

// swiftlint:enable line_length
