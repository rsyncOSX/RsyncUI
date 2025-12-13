//
//  WriteWidgetsURLStringsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog
import RsyncUIDeepLinks

@MainActor
struct WriteWidgetsURLStringsJSON {
    let deeplinks = RsyncUIDeepLinks()
    // They are Sandboxed and Documents catalog, to reade the URL-strings is in a Container
    let estimatestringsandboxcatalog = "Library/Containers/no.blogspot.RsyncUI.WidgetEstimate/Data/Documents"

    private func writeJSONToPersistentStore(jsonData: Data?) {
        if let userHomeDirectoryPath = URL.userHomeDirectoryURLPath?.path() {
            let pathestimate = userHomeDirectoryPath.appending("/" + estimatestringsandboxcatalog)
            let fullpathURL = URL(fileURLWithPath: pathestimate)
            let estimatefileURL = fullpathURL.appendingPathComponent(SharedReference.shared.userconfigjson)
            Logger.process.debugMessageOnly("WriteWidgetsURLStringsJSON: URL-string \(estimatefileURL)")
            if let jsonData {
                do {
                    try jsonData.write(to: estimatefileURL)
                } catch let err {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ urlwidgetstrings: WidgetURLstrings) {
        let encodejsondata = EncodeGeneric()
        do {
            let encodeddata = try encodejsondata.encode(urlwidgetstrings)
            writeJSONToPersistentStore(jsonData: encodeddata)
            Logger.process.debugMessageOnly("WriteWidgetsURLStringsJSON: Writing URL-strings to permanent storage")

        } catch let err {
            Logger.process.errorMessageOnly("WriteWidgetsURLStringsJSON: some ERROR writing user configurations from permanent storage")
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    @discardableResult
    init(_ urlwidgetstrings: WidgetURLstrings?) {
        if let urlwidgetstrings {
            do {
                let valid = try deeplinks.validateURLstring(urlwidgetstrings.urlstringestimate ?? "")
                if valid { encodeJSONData(urlwidgetstrings) }
            } catch let err {
                let error = err
                SharedReference.shared.errorobject?.alert(error: error)
            }
        }
    }
}
// swiftlint:enable line_length