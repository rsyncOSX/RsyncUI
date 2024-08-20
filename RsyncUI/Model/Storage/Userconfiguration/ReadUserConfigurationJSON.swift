//
//  ReadUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class ReadUserConfigurationJSON: PropogateError {
    let path = Homepath()

    func readuserconfiguration() {
        let decodeimport = DecodeGeneric()
        var userconfigurationfile = ""
        if let path = path.fullpathmacserial {
            userconfigurationfile = path + "/" + SharedReference.shared.userconfigjson
        }
        do {
            if let importeddata = try
                decodeimport.decodestringdatafileURL(DecodeUserConfiguration.self, fromwhere: userconfigurationfile)
            {
                UserConfiguration(importeddata)
                Logger.process.info("ReadUserConfigurationJSON: Reading user configurations from permanent storage")
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }
}
