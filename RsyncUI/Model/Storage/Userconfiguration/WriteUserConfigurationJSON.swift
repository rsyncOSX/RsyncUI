//
//  WriteUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//
// swiftlint: disable non_optional_string_data_conversion

import Combine
import Foundation
import OSLog

@MainActor
final class WriteUserConfigurationJSON {
    // path with macserialnumber
    var fullpathmacserial: String?

    // Mac serialnumber
    var macserialnumber: String? {
        if SharedReference.shared.macserialnumber == nil {
            SharedReference.shared.macserialnumber = Macserialnumber().getMacSerialNumber() ?? ""
        }
        return SharedReference.shared.macserialnumber
    }

    var userHomeDirectoryPath: String? {
        let pw = getpwuid(getuid())
        if let home = pw?.pointee.pw_dir {
            let homePath = FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
            return homePath
        } else {
            return nil
        }
    }

    var subscriptons = Set<AnyCancellable>()

    private func writeJSONToPersistentStore(jsonData: Data?) {
        if let fullpathmacserial = fullpathmacserial {
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let usercongigfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.userconfigjson)
            if let jsonData = jsonData {
                do {
                    try jsonData.write(to: usercongigfileURL)
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
    init(_ userconfiguration: UserConfiguration?) {
        fullpathmacserial = (userHomeDirectoryPath ?? "") + SharedReference.shared.configpath + (macserialnumber ?? "")
        userconfiguration.publisher
            .map { userconfiguration in
                userconfiguration
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
                Logger.process.info("WriteUserConfigurationJSON: Writing user configurations to permanent storage")
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}

extension WriteUserConfigurationJSON {
    @MainActor func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

// swiftlint: enable non_optional_string_data_conversion
