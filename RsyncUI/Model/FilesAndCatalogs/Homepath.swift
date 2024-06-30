//
//  Homepath.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/06/2024.
//

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

    var userHomeDirectoryURLPath: URL? {
        let pw = getpwuid(getuid())
        if let home = pw?.pointee.pw_dir {
            let homePath = FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
            return URL(fileURLWithPath: homePath)
        } else {
            return nil
        }
    }

    func getfullpathmacserialcatalogsasstringnames() -> [String]? {
        let fm = FileManager.default
        if let fullpathmacserial = fullpathmacserial {
            var array = [String]()
            array.append(SharedReference.shared.defaultprofile)
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            do {
                for filesandfolders in try fm.contentsOfDirectory(at: fullpathmacserialURL,
                                                                  includingPropertiesForKeys: nil)
                {
                    if filesandfolders.hasDirectoryPath {
                        array.append(filesandfolders.lastPathComponent)
                    }
                }
                return array
            } catch {
                return nil
            }
        }
        return nil
    }

    // Create profile catalog at first start of RsyncOSX.
    // If profile catalog exists - bail out, no need to create
    func createrootprofilecatalog() {
        let fm = FileManager.default
        // First check if profilecatalog exists, if yes bail out
        if let fullpathmacserial = fullpathmacserial,
           let fullpathnomacserial = fullpathnomacserial
        {
            guard fm.locationExists(at: fullpathmacserial, kind: .folder) == false else {
                Logger.process.info("Homepath: root catalog exists")
                return
            }
            // if false then create profile catalogs
            // Creating profile catalalog is a two step task
            // step 1: create profilecatalog
            // step 2: create profilecatalog/macserialnumber
            // config path = /userHomeDirectoryPath/.rsyncosx/macserialnumber

            // Step 1
            let fullpathnomacserialURL = URL(fileURLWithPath: fullpathnomacserial)
            do {
                try fm.createDirectory(at: fullpathnomacserialURL, withIntermediateDirectories: true, attributes: nil)
                Logger.process.info("Homepath: creating root catalog step1")
            } catch let e {
                let error = e
                propogateerror(error: error)
                return
            }

            // Step 2
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            do {
                try fm.createDirectory(at: fullpathmacserialURL, withIntermediateDirectories: true, attributes: nil)
                Logger.process.info("Homepath: creating root catalog step2")
            } catch let e {
                let error = e
                propogateerror(error: error)
                return
            }
        }
    }

    init() {
        fullpathmacserial = (userHomeDirectoryPath ?? "") + SharedReference.shared.configpath + (macserialnumber ?? "")
        fullpathnomacserial = (userHomeDirectoryPath ?? "") + SharedReference.shared.configpath
    }
}

extension Homepath {
    @MainActor func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
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
