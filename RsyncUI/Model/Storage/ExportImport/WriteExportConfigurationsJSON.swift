//
//  WriteExportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/07/2024.
//

import Combine
import Foundation
import OSLog

@MainActor
class WriteExportConfigurationsJSON: PropogateError {
    var subscriptons = Set<AnyCancellable>()

    @discardableResult
    init(_ path: String?, _ configurations: [SynchronizeConfiguration]?) {
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
                WriteStorageJSON(path, result)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}
