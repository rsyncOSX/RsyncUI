//
//  SSHpath.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/06/2024.
//

import Foundation

struct SSHpath {
    // path for sshkeys
    var fullpathsshkeys: String?
    // If global keypath and identityfile is set must split keypath and identifile
    // create a new key require full path
    var identityfile: String?

    // Path to ssh keypath
    var sshkeypath: String? {
        if let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            return Keypathidentityfile(sshkeypathandidentityfile: sshkeypathandidentityfile).fullsshkeypath
        } else {
            return NSHomeDirectory() + "/.ssh"
        }
    }

    // Used when creating ssh keypath
    var onlysshkeypath: String? {
        if let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            return Keypathidentityfile(sshkeypathandidentityfile: sshkeypathandidentityfile).onlysshkeypath
        } else {
            return NSHomeDirectory()
        }
    }

    // SSH identityfile with full keypath if NOT default is used
    // If default, only return defalt value
    var sshkeypathandidentityfile: String? {
        if let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            return Keypathidentityfile(sshkeypathandidentityfile: sshkeypathandidentityfile).identityfile
        } else {
            return "id_rsa"
        }
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

    func getfullpathsshkeys() -> [String]? {
        if let atpath = fullpathsshkeys {
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

    // Create SSH catalog
    // If ssh catalog exists - bail out, no need to create
    func createsshkeyrootpath() {
        if let path = onlysshkeypath {
            let root = Folder.home
            guard root.containsSubfolder(named: path) == false else { return }
            do {
                try root.createSubfolder(at: path)
            } catch let e {
                let error = e
                propogateerror(error: error)
                return
            }
        }
    }

    init() {
        fullpathsshkeys = sshkeypath
        identityfile = sshkeypathandidentityfile
    }
}

extension SSHpath {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}
