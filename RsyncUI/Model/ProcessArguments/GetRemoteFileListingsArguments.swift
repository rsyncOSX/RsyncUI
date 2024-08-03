//
//  GetRemoteFileListingsArguments.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 21.05.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

final class GetRemoteFileListingsArguments {
    private var config: SynchronizeConfiguration?
    private var args: [String]?

    private func remotearguments(recursive: Bool) {
        if let config {
            if config.sshport != nil {
                let eparam = "-e"
                let sshp = "ssh -p"
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
            // Restore arguments
            if config.offsiteServer.isEmpty == false {
                args?.append(config.offsiteUsername + "@" + config.offsiteServer + ":" + config.offsiteCatalog)
            } else {
                args?.append(":" + config.offsiteCatalog)
            }
        }
    }

    private func remoteargumentssnapshot(recursive: Bool) {
        if let config {
            if config.sshport != nil {
                let eparam = "-e"
                let sshp = "ssh -p"
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
            // Restore arguments
            if config.offsiteServer.isEmpty == false {
                if let snapshotnum = config.snapshotnum {
                    if recursive == false {
                        // remote arguments for collect snapshot catalogs only
                        args?.append(config.offsiteUsername + "@" + config.offsiteServer + ":" + config.offsiteCatalog)
                    } else {
                        // remote arguments for recursive collect all files within a snapshot catalog
                        args?.append(config.offsiteUsername + "@" + config.offsiteServer + ":" + config.offsiteCatalog
                            + String(snapshotnum - 1) + "/")
                    }
                }
            } else {
                if let snapshotnum = config.snapshotnum {
                    args?.append(":" + config.offsiteCatalog + String(snapshotnum - 1) + "/")
                }
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
        args
    }

    init(config: SynchronizeConfiguration?,
         recursive: Bool,
         snapshot: Bool)
    {
        guard config != nil else { return }
        self.config = config
        args = [String]()
        if config?.offsiteServer.isEmpty == false {
            if snapshot == true {
                remoteargumentssnapshot(recursive: recursive)
            } else {
                remotearguments(recursive: recursive)
            }
        } else {
            localarguments(recursive: recursive)
        }
    }
}
