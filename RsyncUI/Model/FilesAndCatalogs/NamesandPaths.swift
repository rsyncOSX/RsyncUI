//
//  NamesandPaths.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/07/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation
import SwiftUI

enum Profileorsshrootpath {
    case profileroot
    case sshroot
}

class NamesandPaths {
    // which root to compute? either RsyncOSX profileroot or sshroot
    var profileorsshroot: Profileorsshrootpath?
    // rootpath without macserialnumber
    var fullrootnomacserial: String?
    // rootpath with macserialnumber
    var fullroot: String?
    // If global keypath and identityfile is set must split keypath and identifile
    // create a new key require full path
    var identityfile: String?
    // config path either
    // ViewControllerReference.shared.configpath
    var configpath: String?
    // Which profile to read
    var profile: String?
    // Set which file to read
    var filename: String?
    // plistname for user configuration
    var plistname: String?
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
        case .profileroot:
            fullroot = (userHomeDirectoryPath ?? "") + (configpath ?? "") + (macserialnumber ?? "")
            fullrootnomacserial = (userHomeDirectoryPath ?? "") + (configpath ?? "")
        case .sshroot:
            fullroot = fullsshkeypath
            identityfile = sshidentityfile
        default:
            return
        }
    }

    // Set path and name for reading plist.files
    func setnameandpath() {
        let config = (configpath ?? "") + (macserialnumber ?? "")
        if let profile = self.profile {
            // Use profile
            filename = (userHomeDirectoryPath ?? "") + config + "/" + profile
        } else {
            filename = (userHomeDirectoryPath ?? "") + config + (plistname ?? "")
        }
    }

    init(profileorsshrootpath: Profileorsshrootpath) {
        configpath = SharedReference.shared.configpath
        profileorsshroot = profileorsshrootpath
        setrootpath()
    }

    init(_ profile: String?) {
        configpath = SharedReference.shared.configpath
        self.profile = profile
        setnameandpath()
    }
}

extension NamesandPaths: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
