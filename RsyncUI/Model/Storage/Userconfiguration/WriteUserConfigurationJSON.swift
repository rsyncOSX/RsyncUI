//
//  WriteUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Combine
import Foundation
import OSLog

class WriteUserConfigurationJSON: NamesandPaths {
    var subscriptons = Set<AnyCancellable>()
    // Filename for JSON file
    var filename = SharedReference.shared.userconfigjson

    private func writeJSONToPersistentStore(_ data: String?) {
        if let atpath = fullpathmacserial {
            do {
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filename)
                if let data = data {
                    try file.write(data)
                }
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in the .map operator
    @discardableResult
    init(_ userconfiguration: UserConfiguration?) {
        super.init(.configurations)
        userconfiguration.publisher
            .map { userconfiguration in
                userconfiguration
            }
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonfile)
                Logger.process.info("WriteUserConfigurationJSON: Writing user configurations to permanent storage")
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}
