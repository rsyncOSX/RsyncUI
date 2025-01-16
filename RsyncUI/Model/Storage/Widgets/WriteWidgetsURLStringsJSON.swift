//
//  WriteWidgetsURLStringsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

enum WidgetURLStringsJSON {
    case estimate
    case verify
}

@MainActor
final class WriteWidgetsURLStringsJSON {
    let path = Homepath()

    private func writeJSONToPersistentStore(jsonData: Data?, _ whichurltowrite: WidgetURLStringsJSON) {
        if let userHomeDirectoryPath = path.userHomeDirectoryPath {
            switch whichurltowrite {
            case .estimate:
                let pathestimate = userHomeDirectoryPath.appending("/" + path.estimatestringsandboxcatalog)
                let fullpathURL = URL(fileURLWithPath: pathestimate)
                let estimatefileURL = fullpathURL.appendingPathComponent(SharedReference.shared.userconfigjson)
                Logger.process.info("WriteWidgetsURLStringsJSON: URL-string \(estimatefileURL)")
                if let jsonData {
                    do {
                        try jsonData.write(to: estimatefileURL)
                    } catch let e {
                        let error = e
                        path.propogateerror(error: error)
                    }
                }

            case .verify:
                let pathverify = userHomeDirectoryPath.appending("/" + path.verifystringsandboxcatalog)
                let fullpathURL = URL(fileURLWithPath: pathverify)
                let veirfyfileURL = fullpathURL.appendingPathComponent(SharedReference.shared.userconfigjson)
                Logger.process.info("WriteWidgetsURLStringsJSON: URL-string \(veirfyfileURL)")
                if let jsonData {
                    do {
                        try jsonData.write(to: veirfyfileURL)
                    } catch let e {
                        let error = e
                        path.propogateerror(error: error)
                    }
                }
            }
        }
    }

    private func encodeJSONData(_ urlwidgetstrings: WidgetURLstrings,
                                _ whichurltowrite: WidgetURLStringsJSON)
    {
        let encodejsondata = EncodeGeneric()
        do {
            if let encodeddata = try encodejsondata.encodedata(data: urlwidgetstrings) {
                writeJSONToPersistentStore(jsonData: encodeddata, whichurltowrite)
                Logger.process.info("WriteWidgetsURLStringsJSON: Writing URL-strings to permanent storage")
            }
        } catch let e {
            Logger.process.error("WriteWidgetsURLStringsJSON: some ERROR writing user configurations from permanent storage")
            let error = e
            path.propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ urlwidgetstrings: WidgetURLstrings?, _ whichurltowrite: WidgetURLStringsJSON) {
        if let urlwidgetstrings {
            encodeJSONData(urlwidgetstrings, whichurltowrite)
        }
    }

    deinit {
        Logger.process.info("WriteWidgetsURLStringsJSON: Deinitializing")
    }
}
