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
struct ReadUserConfigurationJSON {
    let path = Homepath()

    func readuserconfiguration() {
        let decodeuserconfiguration = DecodeGeneric()
        var userconfigurationfile = ""
        if let fullpathmacserial = path.fullpathmacserial {
            userconfigurationfile = fullpathmacserial.appending("/") + SharedReference.shared.userconfigjson
        }
        do {
            let importeddata = try
                decodeuserconfiguration.decode(DecodeUserConfiguration.self,
                                               fromFile: userconfigurationfile)

            UserConfiguration(importeddata)
            Logger.process.debugThreadOnly("ReadUserConfigurationJSON: Reading user configurations")
        } catch let err {
            Logger.process.errorMessageOnly("ReadUserConfigurationJSON: some ERROR reading user configurations from permanent storage")
            let error = err
            path.propagateError(error: error)
        }
    }
}
