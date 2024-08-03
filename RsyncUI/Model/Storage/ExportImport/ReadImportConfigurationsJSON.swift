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
    var importconfigurations: [SynchronizeConfiguration]?
    var filenamedatastore = [String]()
    var subscriptons = Set<AnyCancellable>()

    init(_ filenameimport: String, maxhiddenid: Int) {
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
                    var configuration = SynchronizeConfiguration(data[i])
                    configuration.hiddenID = maxhiddenid + 1 + i
                    configuration.dateRun = nil
                    configuration.backupID = "IMPORT: " + (data[i].backupID ?? "")
                    configuration.id = UUID()
                    configurations.append(configuration)
                }
                importconfigurations = configurations
                subscriptons.removeAll()
                Logger.process.info("ReadImportConfigurationsJSON - \(filenameimport, privacy: .public): read import configurations from permanent storage")
            }.store(in: &subscriptons)
    }
}

// swiftlint:enable line_length
