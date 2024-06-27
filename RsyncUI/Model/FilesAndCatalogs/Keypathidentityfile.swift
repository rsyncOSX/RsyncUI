//
//  Keypathidentityfile.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/05/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

@MainActor
struct Keypathidentityfile {
    var fullsshkeypath: String?
    // If global keypath and identityfile is set must split keypath and identifile
    // create a new key require full path
    var identityfile: String?
    var onlysshkeypath: String?

    init(sshkeypathandidentityfile: String) {
        if sshkeypathandidentityfile.first == "~" {
            // must drop identityfile and then set rootpath
            // also drop the "~" character
            var sshkeypathandidentityfilesplit = sshkeypathandidentityfile.split(separator: "/")
            guard sshkeypathandidentityfilesplit.count > 2 else {
                // If anything goes wrong set to default global values
                fullsshkeypath = NSHomeDirectory() + "/.ssh"
                SharedReference.shared.sshkeypathandidentityfile = nil
                identityfile = "id_rsa"
                onlysshkeypath = nil
                return
            }
            identityfile =
                String(sshkeypathandidentityfilesplit[sshkeypathandidentityfilesplit.count - 1])
            sshkeypathandidentityfilesplit.remove(at: sshkeypathandidentityfilesplit.count - 1)
            fullsshkeypath = NSHomeDirectory() +
                sshkeypathandidentityfilesplit.joined(separator: "/").dropFirst()
            onlysshkeypath = String(sshkeypathandidentityfilesplit.joined(separator: "/").dropFirst())
        } else {
            // If anything goes wrong set to default global values
            fullsshkeypath = NSHomeDirectory() + "/.ssh"
            SharedReference.shared.sshkeypathandidentityfile = nil
            identityfile = "id_rsa"
            onlysshkeypath = nil
        }
    }
}
