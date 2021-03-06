//
//  DuArgumentsSsh.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/11/2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// ssh test@web.org " cd catalog; du -h ."

import Foundation

final class DuArgumentsSsh {
    private var config: Configuration?
    private var args: [String]?
    private var command: String?

    private func argumentsDuremote() {
        var remotearg: String?
        guard config != nil else { return }
        guard config!.offsiteUsername.isEmpty == false else { return }
        args = [String]()
        if config!.sshport != nil {
            sshport()
        }
        remotearg = config!.offsiteUsername + "@" + config!.offsiteServer
        args!.append(remotearg!)
        let sizestring = "cd " + config!.offsiteCatalog + ";" + " df  ."
        args!.append(sizestring)
        command = "/usr/bin/ssh"
    }

    private func sshport() {
        args!.append("-p")
        args!.append(String(config!.sshport!))
    }

    func getCommand() -> String? {
        guard command != nil else { return nil }
        return command
    }

    func getArguments() -> [String]? {
        return args
    }

    init(config: Configuration) {
        self.config = config
        argumentsDuremote()
    }
}
