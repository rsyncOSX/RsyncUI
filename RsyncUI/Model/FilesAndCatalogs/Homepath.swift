//
//  Homepath.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/06/2024.
//


import Foundation

struct Homepath {
    // path without macserialnumber
    var fullpathnomacserial: String?
    // path with macserialnumber
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

    func getcatalogsasstringnames() -> [String]? {
        if let atpath = fullpathmacserial {
            var array = [String]()
            array.append(SharedReference.shared.defaultprofile)
            do {
                for folders in try Folder(path: atpath).subfolders {
                    array.append(folders.name)
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
        var root: Folder?
        var catalog: String?
        // First check if profilecatalog exists, if yes bail out
        if let macserialnumber = macserialnumber,
           let fullrootnomacserial = fullpathnomacserial
        {
            do {
                let pathexists = try Folder(path: fullrootnomacserial).containsSubfolder(named: macserialnumber)
                guard pathexists == false else { return }
            } catch {
                // if fails then create profile catalogs
                // Creating profile catalalog is a two step task
                // 1: create profilecatalog
                // 2: create profilecatalog/macserialnumber
                // config path (/.rsyncosx)
                catalog = SharedReference.shared.configpath
                root = Folder.home
                do {
                    try root?.createSubfolder(at: catalog ?? "")
                } catch let e {
                    let error = e
                    propogateerror(error: error)
                    return
                }
                // */
                if let macserialnumber = self.macserialnumber,
                   let fullrootnomacserial = fullpathnomacserial
                {
                    do {
                        try Folder(path: fullrootnomacserial).createSubfolder(at: macserialnumber)
                    } catch let e {
                        let error = e
                        propogateerror(error: error)
                        return
                    }
                }
            }
        }
    }

    init() {
        fullpathmacserial = (userHomeDirectoryPath ?? "") + SharedReference.shared.configpath + (macserialnumber ?? "")
        fullpathnomacserial = (userHomeDirectoryPath ?? "") + SharedReference.shared.configpath
    }
}

extension Homepath {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

