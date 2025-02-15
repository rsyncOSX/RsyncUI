//
//  ReadUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
struct ReadUserConfigurationJSON {
    let path = Homepath()

    func readuserconfiguration() {
        let decodeuserconfiguration = DecodeGeneric()
        var userconfigurationfile = ""
        if let path = path.fullpathmacserial {
            userconfigurationfile = path + "/" + SharedReference.shared.userconfigjson
        }
        do {
            if let importeddata = try
                decodeuserconfiguration.decodestringdatafileURL(DecodeUserConfiguration.self,
                                                                fromwhere: userconfigurationfile)
            {
                UserConfiguration(importeddata)
                Logger.process.info("ReadUserConfigurationJSON: Reading user configurations from permanent storage")
            }

        } catch let e {
            Logger.process.error("ReadUserConfigurationJSON: some ERROR reading user configurations from permanent storage")
            let error = e
            path.propogateerror(error: error)
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

// swiftlint:enable line_length
