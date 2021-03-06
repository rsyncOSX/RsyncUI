//
//  rsyncArguments.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 06.03.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

final class RsyncParametersSingleFilesArguments {
    let archive: String = "--archive"
    let verbose: String = "--verbose"
    let compress: String = "--compress"
    let eparam: String = "-e"
    let ssh: String = "ssh"
    let sshp: String = "ssh -p"
    let dryrun: String = "--dry-run"

    private var config: Configuration?
    private var args: [String]?

    // Set parameters for rsync
    private func arguments(remoteFile: String?, localCatalog: String?, drynrun: Bool?) {
        if let config = self.config {
            // Drop the two first characeters ("./") as result from the find . -name
            let remote_with_whitespace = String(remoteFile!.dropFirst(2))
            // Replace remote for white spaces
            let whitespace: String = "\\ "
            let remote = remote_with_whitespace.replacingOccurrences(of: " ", with: whitespace)
            let local: String = localCatalog!
            if config.sshport != nil {
                args?.append(eparam)
                args?.append(sshp + " " + String(config.sshport!))
            } else {
                args?.append(eparam)
                args?.append(ssh)
            }
            args?.append(archive)
            args?.append(verbose)
            // If copy over network compress files
            if config.offsiteServer.isEmpty {
                args?.append(compress)
            }
            // Set dryrun or not
            if drynrun != nil {
                if drynrun == true {
                    args?.append(dryrun)
                }
            }
            if config.offsiteServer.isEmpty {
                args?.append(config.offsiteCatalog + remote)
            } else {
                let rarg = config.offsiteUsername + "@" + config.offsiteServer + ":" + config.offsiteCatalog + remote
                args?.append(rarg)
            }
            args?.append(local)
        }
    }

    func getArguments() -> [String]? {
        return args
    }

    init(config: Configuration?, remoteFile: String?, localCatalog: String?, drynrun: Bool?) {
        if let config = config {
            self.config = config
            args = [String]()
            arguments(remoteFile: remoteFile, localCatalog: localCatalog, drynrun: drynrun)
        }
    }
}
