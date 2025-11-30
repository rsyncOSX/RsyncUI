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
struct WriteUserConfigurationJSON {
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
                    path.propagateError(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ userconfiguration: UserConfiguration) {
        let encodejsondata = EncodeGeneric()
        do {
            let encodeddata = try encodejsondata.encode(userconfiguration)
            writeJSONToPersistentStore(jsonData: encodeddata)
            Logger.process.debugmessageonly("WriteUserConfigurationJSON: Writing user configurations to permanent storage")

        } catch let e {
            Logger.process.error("WriteUserConfigurationJSON: some ERROR writing user configurations from permanent storage")
            let error = e
            path.propagateError(error: error)
        }
    }

    @discardableResult
    init(_ userconfiguration: UserConfiguration?) {
        if let userconfiguration {
            encodeJSONData(userconfiguration)
        }
    }
}
