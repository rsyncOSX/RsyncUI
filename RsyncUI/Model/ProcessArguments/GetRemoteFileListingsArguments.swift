//
//  getRemoteFilelist.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 21.05.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

final class GetRemoteFileListingsArguments {
    private var config: Configuration?
    private var args: [String]?

    private func remotearguments(recursive: Bool) {
        if let config = self.config {
            if config.sshport != nil {
                let eparam: String = "-e"
                let sshp: String = "ssh -p"
                args?.append(eparam)
                args?.append(sshp + String(config.sshport!))
            } else {
                let eparam: String = "-e"
                let ssh: String = "ssh"
                args?.append(eparam)
                args?.append(ssh)
            }
            if recursive {
                args?.append("-r")
            }
            args?.append("--list-only")
            if config.offsiteServer.isEmpty == false {
                args?.append(config.offsiteUsername + "@" + config.offsiteServer + ":" + config.offsiteCatalog)
            } else {
                args?.append(":" + config.offsiteCatalog)
            }
        }
    }

    private func localarguments(recursive: Bool) {
        if recursive {
            args?.append("-r")
        }
        args?.append("--list-only")
        args?.append(config?.offsiteCatalog ?? "")
    }

    func getArguments() -> [String]? {
        return args
    }

    init(config: Configuration?, recursive: Bool) {
        guard config != nil else { return }
        self.config = config
        args = [String]()
        if config?.offsiteServer.isEmpty == false {
            remotearguments(recursive: recursive)
        } else {
            localarguments(recursive: recursive)
        }
    }
}
