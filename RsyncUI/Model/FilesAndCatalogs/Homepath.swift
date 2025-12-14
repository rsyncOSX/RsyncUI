//
//  Homepath.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/06/2024.
//

//
//  Homepath.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/06/2024.
//
// swiftlint:disable line_length

import Foundation
import OSLog

@MainActor
struct Homepath {
    // full path without macserialnumber
    var fullpathnomacserial: String?
    // full path with macserialnumber
    var fullpathmacserial: String?

    // Documentscatalog
    var documentscatalog: String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        return paths.firstObject as? String
    }

    // Mac serialnumber
    var macserialnumber: String? {
        if SharedReference.shared.macserialnumber == nil {
            SharedReference.shared.macserialnumber = Macserialnumber().getMacSerialNumber()
        }
        return SharedReference.shared.macserialnumber
    }

    func getFullPathMacSerialCatalogsAsStringNames() -> [String] {
        let fmanager = FileManager.default
        guard let fullpathmacserial else {
            Logger.process.warning("Homepath: fullpathmacserial is nil")
            return []
        }

        var array = [String]()
        let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)

        do {
            for filesandfolders in try fmanager.contentsOfDirectory(at: fullpathmacserialURL,
                                                              includingPropertiesForKeys: nil)
                where filesandfolders.hasDirectoryPath {
                array.append(filesandfolders.lastPathComponent)
            }
            Logger.process.info("Homepath: the following folders were found in \(fullpathmacserial): \(array)")
            return array
        } catch {
            Logger.process.errorMessageOnly("Homepath: failed to read directory at \(fullpathmacserial): \(error.localizedDescription)")
            return []
        }
    }

    // Create profile catalog at first start of RsyncOSX.
    // If profile catalog exists - bail out, no need to create
    func createRootProfileCatalog() {
        let fm = FileManager.default

        // First check if profilecatalog exists, if yes bail out
        guard let fullpathmacserial,
              let fullpathnomacserial
        else {
            Logger.process.errorMessageOnly("Homepath: paths are nil, cannot create root catalog")
            return
        }

        guard fm.locationExists(at: fullpathmacserial, kind: .folder) == false else {
            Logger.process.info("Homepath: root catalog exists")
            return
        }

        // if false then create profile catalogs
        // Creating profile catalog is a two step task
        // step 1: create profilecatalog
        // step 2: create profilecatalog/macserialnumber
        // config path = /userHomeDirectoryPath/.rsyncosx/macserialnumber

        // Step 1
        let fullpathnomacserialURL = URL(fileURLWithPath: fullpathnomacserial)
        do {
            try fm.createDirectory(at: fullpathnomacserialURL, withIntermediateDirectories: true, attributes: nil)
            Logger.process.info("Homepath: creating root catalog step1")
        } catch {
            propagateError(error: error)
            return
        }

        // Step 2
        let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
        do {
            try fm.createDirectory(at: fullpathmacserialURL, withIntermediateDirectories: true, attributes: nil)
            Logger.process.info("Homepath: creating root catalog step2")
        } catch {
            propagateError(error: error)
        }
    }

    func propagateError(error: Error) {
        Logger.process.errorMessageOnly("Homepath: error occurred - \(error.localizedDescription)")
        SharedReference.shared.errorobject?.alert(error: error)
    }

    init() {
        let homePath = URL.userHomeDirectoryURLPath?.path() ?? ""
        let configPath = SharedReference.shared.configpath
        fullpathnomacserial = homePath + configPath.appending("/")
        fullpathmacserial = homePath + configPath.appending("/") + (macserialnumber ?? "")
    }
}

extension FileManager {
    func locationExists(at path: String, kind: LocationKind) -> Bool {
        var isFolder: ObjCBool = false

        guard fileExists(atPath: path, isDirectory: &isFolder) else {
            return false
        }

        switch kind {
        case .file: return !isFolder.boolValue
        case .folder: return isFolder.boolValue
        }
    }
}

/// Enum describing various kinds of locations that can be found on a file system.
public enum LocationKind {
    /// A file can be found at the location.
    case file
    /// A folder can be found at the location.
    case folder
}

// swiftlint:enable line_length
