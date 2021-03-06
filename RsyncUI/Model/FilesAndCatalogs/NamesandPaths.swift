//
//  NamesandPaths.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/07/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation
import SwiftUI

enum WhatToReadWrite {
    case schedule
    case configuration
    case userconfig
    case none
}

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
    // ViewControllerReference.shared.configpath or RcloneReference.shared.configpath
    var configpath: String?
    // Name set for schedule, configuration or config
    var plistname: String?
    // key in objectForKey, e.g key for reading what
    var key: String?
    // Which profile to read
    var profile: String?
    // task to do
    var task: WhatToReadWrite?
    // Set which file to read
    var filename: String?
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
            if SharedReference.shared.usenewconfigpath == true {
                fullroot = (userHomeDirectoryPath ?? "") + (configpath ?? "") + (macserialnumber ?? "")
                fullrootnomacserial = (userHomeDirectoryPath ?? "") + (configpath ?? "")
            } else {
                fullroot = (documentscatalog ?? "") + (configpath ?? "") + (macserialnumber ?? "")
                fullrootnomacserial = (documentscatalog ?? "") + (configpath ?? "")
            }
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
        let plist = (plistname ?? "")
        if let profile = self.profile {
            // Use profile
            if SharedReference.shared.usenewconfigpath == true {
                filename = (userHomeDirectoryPath ?? "") + config + "/" + profile + plist
            } else {
                filename = (documentscatalog ?? "") + config + "/" + profile + plist
            }
        } else {
            if SharedReference.shared.usenewconfigpath == true {
                filename = (userHomeDirectoryPath ?? "") + config + plist
            } else {
                filename = (documentscatalog ?? "") + config + plist
            }
        }
    }

    // Set preferences for which data to read or write
    func setpreferencesforreadingplist(whattoreadwrite: WhatToReadWrite) {
        task = whattoreadwrite
        switch task ?? .none {
        case .schedule:
            plistname = SharedReference.shared.scheduleplist
            key = SharedReference.shared.schedulekey
        case .configuration:
            plistname = SharedReference.shared.configurationsplist
            key = SharedReference.shared.configurationskey
        case .userconfig:
            plistname = SharedReference.shared.userconfigplist
            key = SharedReference.shared.userconfigkey
        case .none:
            plistname = nil
            key = nil
        }
    }

    init(profileorsshrootpath: Profileorsshrootpath) {
        configpath = Configpath().configpath
        profileorsshroot = profileorsshrootpath
        setrootpath()
    }

    init(profile: String?, whattoreadwrite: WhatToReadWrite) {
        configpath = Configpath().configpath
        self.profile = profile
        setpreferencesforreadingplist(whattoreadwrite: whattoreadwrite)
        setnameandpath()
    }
}

extension NamesandPaths: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
