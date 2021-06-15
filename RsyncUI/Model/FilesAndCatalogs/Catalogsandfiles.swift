//
//  files.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Files
import Foundation

class Catalogsandfiles: NamesandPaths {
    func getfilesasstringnames() -> [String]? {
        if let atpath = fullpathmacserial {
            do {
                var array = [String]()
                for file in try Folder(path: atpath).files {
                    array.append(file.name)
                }
                return array
            } catch {
                return nil
            }
        }
        return nil
    }

    func getcatalogsasstringnames() -> [String]? {
        if let atpath = fullpathmacserial {
            var array = [String]()
            array.append(NSLocalizedString("Default profile", comment: "default profile"))
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
        if let macserialnumber = self.macserialnumber,
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

    // Create SSH catalog
    // If ssh catalog exists - bail out, no need to create
    func createsshkeyrootpath() {
        if let path = onlysshkeypath {
            let root = Folder.home
            guard root.containsSubfolder(named: path) == false else { return }
            do {
                try root.createSubfolder(at: path)
            } catch {
                // let error = e
                // propogateerror(error: error)
                return
            }
        }
    }

    override init(_ whichroot: Rootpath) {
        super.init(whichroot)
    }
}
