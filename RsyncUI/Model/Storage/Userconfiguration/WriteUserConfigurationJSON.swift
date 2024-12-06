//
//  WriteUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class WriteUserConfigurationJSON {
    let path = Homepath()

    private func writeJSONToPersistentStore(jsonData: Data?) {
        if let fullpathmacserial = path.fullpathmacserial {
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let usercongigfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.userconfigjson)
            if let jsonData {
                do {
                    try jsonData.write(to: usercongigfileURL)
                } catch let e {
                    let error = e
                    path.propogateerror(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ userconfiguration: UserConfiguration) {
        let encodejsondata = EncodeGeneric()
        do {
            if let encodeddata = try encodejsondata.encodedata(data: userconfiguration) {
                writeJSONToPersistentStore(jsonData: encodeddata)
                Logger.process.info("WriteUserConfigurationJSON: Writing user configurations to permanent storage")
            }
        } catch let e {
            Logger.process.error("WriteUserConfigurationJSON: some ERROR writing user configurations from permanent storage")
            let error = e
            path.propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ userconfiguration: UserConfiguration?) {
        if let userconfiguration {
            encodeJSONData(userconfiguration)
        }
    }

    deinit {
        Logger.process.info("WriteUserConfigurationJSON: Deinitializing")
    }
}
