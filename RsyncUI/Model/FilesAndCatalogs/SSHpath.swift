//
//  SSHpath.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/06/2024.
//

import Foundation
import OSLog

@MainActor
struct SSHpath: PropogateError {
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
        let fm = FileManager.default
        if let atpath = fullpathsshkeys {
            var array = [String]()
            do {
                for files in try fm.contentsOfDirectory(atPath: atpath) {
                    array.append(files)
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
        let fm = FileManager.default
        if let onlysshkeypath = onlysshkeypath,
           let userHomeDirectoryPath = userHomeDirectoryPath
        {
            let sshkeypathString = userHomeDirectoryPath + "/." + onlysshkeypath
            guard fm.locationExists(at: sshkeypathString, kind: .folder) == false else {
                Logger.process.info("SSHpath: ssh catalog exists")
                return
            }

            let userHomeDirectoryPathURL = URL(fileURLWithPath: userHomeDirectoryPath)
            let sshkeypathlURL = userHomeDirectoryPathURL.appendingPathComponent("/." + onlysshkeypath)

            do {
                try fm.createDirectory(at: sshkeypathlURL, withIntermediateDirectories: true, attributes: nil)
                Logger.process.info("SSHpath: creating ssh catalog")
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
