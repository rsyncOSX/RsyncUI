//
//  ReadConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import Combine
import Foundation
import OSLog

@MainActor
final class ReadConfigurationJSON {
    var configurations: [SynchronizeConfiguration]?
    var filenamedatastore = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()
    let path = Homepath()

    private func createdefaultfilelogrecords(_ profile: String?) {
        var defaultlogrecords = [LogRecords()]
        guard defaultlogrecords.count == 1 else { return }
        // No file, write new file with default values
        Logger.process.info("ReadConfigurationJSON: \(profile ?? "default profile", privacy: .public), Creating default file for LogRecords")
        defaultlogrecords[0].dateStart = Date().en_us_string_from_date()
        WriteLogRecordsJSON(profile, defaultlogrecords)
    }

    init(_ profile: String?) {
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename = ""
                if let profile = profile, let path = path.fullpathmacserial {
                    filename = path + "/" + profile + "/" + filenamejson
                } else {
                    if let path = path.fullpathmacserial {
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
                    self.createdefaultfilelogrecords(profile)
                }
            } receiveValue: { [unowned self] data in
                var configurations = [SynchronizeConfiguration]()
                for i in 0 ..< data.count {
                    var configuration = SynchronizeConfiguration(data[i])
                    configuration.profile = profile
                    configurations.append(configuration)
                }
                self.configurations = configurations
                subscriptons.removeAll()
                Logger.process.info("ReadConfigurationJSON - \(profile ?? "default profile", privacy: .public): read configurations from permanent storage")
            }.store(in: &subscriptons)
    }
}

// swiftlint:enable line_length
