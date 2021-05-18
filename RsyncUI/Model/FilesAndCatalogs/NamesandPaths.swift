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
    // which root to compute? either RsyncOSX profileroot or sshroot
    var profileorsshroot: Rootpath?
    // rootpath without macserialnumber
    var fullrootnomacserial: String?
    // rootpath with macserialnumber
    var fullroot: String?
    // If global keypath and identityfile is set must split keypath and identifile
    // create a new key require full path
    var identityfile: String?
    // config path either
    // ViewControllerReference.shared.configpath
    // let configpath: String = "/.rsyncosx/"
    var configpath: String?
    // Which profile to read
    var profile: String?

    // Documentscatalog
    var documentscatalog: String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        return (paths.firstObject as? String)
    }

    // Path to ssh keypath
    var fullsshkeypath: String? {
        if let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            return Keypathidentityfile(sshkeypathandidentityfile: sshkeypathandidentityfile).fullsshkeypath
        } else {
            return NSHomeDirectory() + "/.ssh"
        }
    }

    var onlysshkeypath: String? {
        if let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            return Keypathidentityfile(sshkeypathandidentityfile: sshkeypathandidentityfile).onlysshkeypath
        } else {
            return NSHomeDirectory()
        }
    }

    // path to ssh identityfile
    var sshidentityfile: String? {
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

    func setrootpath() {
        switch profileorsshroot {
        case .configurations:
            fullroot = (userHomeDirectoryPath ?? "") + (configpath ?? "") + (macserialnumber ?? "")
            fullrootnomacserial = (userHomeDirectoryPath ?? "") + (configpath ?? "")
        case .ssh:
            fullroot = fullsshkeypath
            identityfile = sshidentityfile
        default:
            return
        }
    }

    init(profileorsshrootpath: Rootpath) {
        configpath = SharedReference.shared.configpath
        profileorsshroot = profileorsshrootpath
        setrootpath()
    }

    init(_ profile: String?) {
        configpath = SharedReference.shared.configpath
        self.profile = profile
    }
}

extension NamesandPaths: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
