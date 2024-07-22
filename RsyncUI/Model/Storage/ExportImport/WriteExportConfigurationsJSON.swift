//
//  WriteExportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/07/2024.
//

// swiftlint:disable line_length

import Combine
import Foundation
import OSLog

@MainActor
class WriteExportConfigurationsJSON: PropogateError {
    var subscriptons = Set<AnyCancellable>()
    var exportpath: String?

    private func writeJSONToPersistentStore(jsonData: Data?) {
        if let exportpath = exportpath {
            let exportconfigurationfileURL = URL(fileURLWithPath: exportpath)

            if let jsonData = jsonData {
                do {
                    try jsonData.write(to: exportconfigurationfileURL)
                    Logger.process.info("WriteExportConfigurationsJSON - \(exportpath), privacy: .public): write export configurations to permanent storage")
                } catch let e {
                    let error = e
                    propogateerror(error: error)
                }
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in the .map operator
    @discardableResult
    init(_ path: String?, _ configurations: [SynchronizeConfiguration]?) {
        exportpath = path

        configurations.publisher
            .map { configurations -> [DecodeConfiguration] in
                var data = [DecodeConfiguration]()
                for i in 0 ..< configurations.count {
                    data.append(DecodeConfiguration(configurations[i]))
                }
                return data
            }
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                writeJSONToPersistentStore(jsonData: result)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}

// swiftlint:enable line_length
