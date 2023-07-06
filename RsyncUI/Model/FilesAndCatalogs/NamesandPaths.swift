//
//  NamesandPaths.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/07/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation
import SwiftUI

enum Rootpath {
    case configurations
    case ssh
}

class NamesandPaths {
    // path without macserialnumber
    var fullpathnomacserial: String?
    // path with macserialnumber
    var fullpathmacserial: String?
    // path for sshkeys
    var fullpathsshkeys: String?
    // If global keypath and identityfile is set must split keypath and identifile
    // create a new key require full path
    var identityfile: String?
    // configuration path, ViewControllerReference.shared.configpath
    // let configpath: String = "/.rsyncosx/"
    var configpath: String?

    // Documentscatalog
    var documentscatalog: String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        return paths.firstObject as? String
    }

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

    // SANDBOX - replaced userHomeDirectoryPath with documentscatalog
    // Configurations are living inside the Sandbox
    init(_ path: Rootpath) {
        configpath = SharedReference.shared.configpath
        switch path {
        case .configurations:
            fullpathmacserial = (userHomeDirectoryPath ?? "") + (configpath ?? "") + (macserialnumber ?? "")
            fullpathnomacserial = (userHomeDirectoryPath ?? "") + (configpath ?? "")
        case .ssh:
            fullpathsshkeys = sshkeypath
            identityfile = sshkeypathandidentityfile
        }
    }
}

extension NamesandPaths {
    func alerterror(error: Error) {
        SharedReference.shared.errorobject?.alerterror(error: error)
    }
}
