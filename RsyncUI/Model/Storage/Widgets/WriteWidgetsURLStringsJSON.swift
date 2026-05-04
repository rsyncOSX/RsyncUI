//
//  WriteWidgetsURLStringsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation
import OSLog
import RsyncUIDeepLinks

@MainActor
enum WriteWidgetsURLStringsJSON {
    /// They are Sandboxed and Documents catalog, to reade the URL-strings is in a Container
    static let estimatestringsandboxcatalog = "Library/Containers/no.blogspot.RsyncUI.WidgetEstimate/Data/Documents"

    static func write(_ urlwidgetstrings: WidgetURLstrings?) async {
        guard let urlwidgetstrings else { return }

        do {
            let valid = try RsyncUIDeepLinks().validateURLstring(urlwidgetstrings.urlstringestimate ?? "")
            guard valid else { return }
        } catch {
            SharedReference.shared.errorobject?.alert(error: error)
            return
        }

        guard let userHomeDirectoryPath = URL.userHomeDirectoryURLPath?.path() else { return }

        let pathestimate = userHomeDirectoryPath.appending("/" + estimatestringsandboxcatalog)
        let fullpathURL = URL(fileURLWithPath: pathestimate)
        let estimatefileURL = fullpathURL.appendingPathComponent(SharedReference.shared.userconfigjson)
        let snapshot = StoredWidgetURLStrings(urlstringestimate: urlwidgetstrings.urlstringestimate)

        Logger.process.debugMessageOnly("WriteWidgetsURLStringsJSON: URL-string \(estimatefileURL)")

        do {
            try await SharedJSONStorageWriter.shared.write(snapshot, to: estimatefileURL)
            Logger.process.debugMessageOnly("WriteWidgetsURLStringsJSON: Writing URL-strings to permanent storage")
        } catch {
            Logger.process.errorMessageOnly("WriteWidgetsURLStringsJSON: ERROR writing user configurations to permanent storage")
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }
}

private struct StoredWidgetURLStrings: Codable {
    var urlstringestimate: String?
}
