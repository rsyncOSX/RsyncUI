//
//  VerifyConfiguration.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import Foundation
import OSLog
import ProcessCommand

enum ValidateInputError: LocalizedError {
    case localcatalog
    case offsiteusername
    case notconnected
    case offsiteserver
    case snapshotnum
    case rsyncversion2

    var errorDescription: String? {
        switch self {
        case .localcatalog:
            "Either local or remote cannot be empty"
        case .offsiteusername:
            "Username cannot be empty"
        case .notconnected:
            "Not connected, cannot create task"
        case .offsiteserver:
            "Servername cannot be empty"
        case .snapshotnum:
            "Snapshotnum must be 1"
        case .rsyncversion2:
            "Snapshot and syncremote require rsync ver3.x"
        }
    }
}

struct AppendTask {
    var newtask: String
    var newlocalCatalog: String
    var newoffsiteCatalog: String
    var newtrailingslashoptions: TrailingSlash
    // Can be nil
    var newoffsiteUsername: String?
    var newoffsiteServer: String?
    var newbackupID: String?
    // Use hiddenID for update
    var hiddenID: Int?
    // For snapshottask, snapshotnum might be reset
    var snapshotnum: Int?

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingslashoptions: TrailingSlash,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?) {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newtrailingslashoptions = trailingslashoptions
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
    }

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingslashoptions: TrailingSlash,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?,
         _ updatedhiddenID: Int,
         _ updatesnapshotnum: Int?) {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newtrailingslashoptions = trailingslashoptions
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
        hiddenID = updatedhiddenID
        snapshotnum = updatesnapshotnum
    }
}

@MainActor
final class VerifyConfiguration: Connected {
    let archive: String = "--archive"
    let verbose: String = "--verbose"
    let compress: String = "--compress"
    // let delete: String = "--delete"

    // Verify parameters for new config.
    func verify(_ data: AppendTask) -> SynchronizeConfiguration? {
        var newconfig = SynchronizeConfiguration()
        newconfig.task = data.newtask
        newconfig.backupID = data.newbackupID ?? ""
        newconfig.localCatalog = data.newlocalCatalog
        newconfig.offsiteCatalog = data.newoffsiteCatalog
        newconfig.offsiteServer = data.newoffsiteServer ?? ""
        newconfig.offsiteUsername = data.newoffsiteUsername ?? ""
        newconfig.parameter1 = archive
        newconfig.parameter2 = verbose
        newconfig.parameter3 = compress
        // newconfig.parameter4 = delete
        // The default delete parameter is removed
        // If want to use delete, set it in userparams
        newconfig.parameter4 = ""
        newconfig.dateRun = ""
        newconfig.hiddenID = data.hiddenID ?? -1

        // First od all verify that either source or destination is empty
        // If one is empty bail out

        guard data.newlocalCatalog.isEmpty == false else {
            let error = ValidateInputError.localcatalog
            propagateError(error: error)
            return nil
        }

        guard data.newoffsiteCatalog.isEmpty == false else {
            let error = ValidateInputError.localcatalog
            propagateError(error: error)
            return nil
        }

        if (data.snapshotnum ?? 0) > 0 {
            newconfig.snapshotnum = data.snapshotnum
        } else {
            newconfig.snapshotnum = nil
        }

        // Check what to do with trailing slash
        switch data.newtrailingslashoptions {
        // Remove any trailing slashes
        // If no trailing slash added, accept data
        case .do_not_add:
            if data.newlocalCatalog.hasSuffix("/") == true {
                let catalog = data.newlocalCatalog.dropLast()
                newconfig.localCatalog = String(catalog)
            } else {
                newconfig.localCatalog = data.newlocalCatalog
            }
            if data.newoffsiteCatalog.hasSuffix("/") == true {
                let catalog = data.newoffsiteCatalog.dropLast()
                newconfig.offsiteCatalog = String(catalog)
            } else {
                newconfig.offsiteCatalog = data.newoffsiteCatalog
            }
        // Check for adding trailing slash
        // If trailing slash is already added, accept the data
        case .add:
            if data.newlocalCatalog.hasSuffix("/") == false {
                var catalog = data.newlocalCatalog
                catalog += "/"
                newconfig.localCatalog = catalog
            } else {
                newconfig.localCatalog = data.newlocalCatalog
            }
            if data.newoffsiteCatalog.hasSuffix("/") == false {
                var catalog = data.newoffsiteCatalog
                catalog += "/"
                newconfig.offsiteCatalog = catalog
            } else {
                newconfig.offsiteCatalog = data.newoffsiteCatalog
            }
        // Do not check for trailing slash or not
        case .do_not_check:
            newconfig.localCatalog = data.newlocalCatalog
            newconfig.offsiteCatalog = data.newoffsiteCatalog
        }

        // New snapshot task
        if data.newtask == SharedReference.shared.snapshot, newconfig.snapshotnum == nil {
            newconfig.task = SharedReference.shared.snapshot
            newconfig.snapshotnum = 1
        }
        if data.newtask == SharedReference.shared.syncremote {
            newconfig.task = SharedReference.shared.syncremote
        }
        do {
            let validated = try validateinput(config: newconfig)
            guard validated == true else { return nil }
        } catch let e {
            let error = e
            propagateError(error: error)
            return nil
        }
        // If validated and snapshottask create remote snapshotcatalog
        // Must be connected to create base remote snapshot catalog
        if data.newtask == SharedReference.shared.snapshot, newconfig.snapshotnum == 1 {
            // If connected create base remote snapshotcatalog
            snapshotcreateremotecatalog(config: newconfig)
        }
        // Return a new configuration to be appended
        return newconfig
    }

    // Create remote snapshot catalog
    private func snapshotcreateremotecatalog(config: SynchronizeConfiguration) {
        guard config.offsiteServer.isEmpty == false else { return }
        let args = ArgumentsSnapshotCreateCatalog(config: config)

        let handlers = CreateCommandHandlers().createcommandhandlers(
            processtermination: { _, _ in })

        let process = ProcessCommand(command: args.getCommand(),
                                     arguments: args.getArguments(),
                                     handlers: handlers)
        do {
            try process.executeProcess()
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    // Validate input, throws errors
    private func validateinput(config: SynchronizeConfiguration) throws -> Bool {
        guard config.localCatalog.isEmpty == false,
              config.offsiteCatalog.isEmpty == false
        else {
            throw ValidateInputError.localcatalog
        }
        if config.offsiteServer.isEmpty == false {
            guard config.offsiteUsername.isEmpty == false else {
                throw ValidateInputError.offsiteusername
            }
        }
        if config.offsiteUsername.isEmpty == false {
            guard config.offsiteServer.isEmpty == false else {
                throw ValidateInputError.offsiteserver
            }
        }

        if config.task == SharedReference.shared.snapshot {
            // Verify rsync version 3.x
            guard SharedReference.shared.rsyncversion3 else {
                Logger.process.warning("VerifyConfiguration: snapshots requiere version 3.x of rsync.")
                throw ValidateInputError.rsyncversion2
            }

            guard config.snapshotnum != nil else {
                Logger.process.warning("VerifyConfiguration: snapshotnum not set.")
                throw ValidateInputError.snapshotnum
            }
            // also check if connected because creating base Remote folder if remote server
            // must be connected to create remote base catalog
            guard connected(server: config.offsiteServer) else {
                Logger.process.warning("VerifyConfiguration: not connected to remote server.")
                throw ValidateInputError.notconnected
            }
        }

        if config.task == SharedReference.shared.syncremote {
            // Verify rsync version 3.x
            guard SharedReference.shared.rsyncversion3 else {
                Logger.process.warning("VerifyConfiguration: syncremote requiere version 3.x of rsync.")
                throw ValidateInputError.rsyncversion2
            }

            guard config.offsiteServer.isEmpty == false, config.offsiteUsername.isEmpty == false else {
                throw ValidateInputError.offsiteusername
            }
        }
        return true
    }

    func propagateError(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

protocol Connected {
    func connected(server: String?) -> Bool
}

extension Connected {
    func connected(server: String?) -> Bool {
        if let server {
            let port = 22
            if server.isEmpty == false {
                let tcpconnection = TCPconnections()
                let success = tcpconnection.verifyTCPconnection(server, port: port, timeout: 1)
                return success
            } else {
                return true
            }
        }
        return false
    }
}
