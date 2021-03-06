//
//  scpArgumentsSsh.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 27.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsSsh {
    private var myremote: UniqueserversandLogins?
    private var args: [String]?
    private var command: String?
    private var globalsshkeypathandidentityfile: String?

    // Set parameters for ssh-copy-id for copy public ssh key to server
    // ssh-address = "backup@server.com"
    // ssh-copy-id -i $ssh-keypath -p port $ssh-address
    func argumentssshcopyid() -> String? {
        guard myremote != nil else { return nil }
        guard (myremote?.offsiteServer?.isEmpty ?? true) == false else { return nil }
        args = [String]()
        command = "/usr/bin/ssh-copy-id"
        args?.append(command ?? "")
        args?.append("-i")
        args?.append(globalsshkeypathandidentityfile ?? "")
        if SharedReference.shared.sshport != nil { sshport() }
        let usernameandservername = (myremote?.offsiteUsername ?? "") + "@" + (myremote?.offsiteServer ?? "")
        args?.append(usernameandservername)
        return args?.joined(separator: " ")
    }

    // Check if pub key exists on remote server
    // ssh -p port -i $ssh-keypath $ssh-address
    func argumentscheckremotepubkey() -> String? {
        guard myremote != nil else { return nil }
        guard (myremote?.offsiteServer?.isEmpty ?? true) == false else { return nil }
        args = [String]()
        command = "/usr/bin/ssh"
        args?.append(command ?? "")
        if SharedReference.shared.sshport != nil { sshport() }
        args?.append("-i")
        args?.append(globalsshkeypathandidentityfile ?? "")
        let usernameandservername = (myremote?.offsiteUsername ?? "") + "@" + (myremote?.offsiteServer ?? "")
        args?.append(usernameandservername)
        return args?.joined(separator: " ")
    }

    private func sshport() {
        args?.append("-p")
        args?.append(String(SharedReference.shared.sshport ?? 22))
    }

    // Create local key with ssh-keygen
    // Generate a passwordless RSA keyfile -N sets password, "" makes it blank
    // ssh-keygen -t rsa -N "" -f $ssh-keypath
    func argumentscreatekey() -> [String]? {
        args = [String]()
        args?.append("-t")
        args?.append("rsa")
        args?.append("-N")
        args?.append("")
        args?.append("-f")
        args?.append(globalsshkeypathandidentityfile ?? "")
        return args
    }

    func getCommand() -> String? {
        return "/usr/bin/ssh-keygen"
    }

    init(remote: UniqueserversandLogins?, sshkeypathandidentityfile: String?) {
        myremote = remote
        globalsshkeypathandidentityfile = sshkeypathandidentityfile ?? ""
    }
}
