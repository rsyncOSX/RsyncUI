//
//  VerifyConfiguration.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//
// swiftlint:disable cyclomatic_complexity function_body_length

import Foundation
import OSLog

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
            return "Either local or remote cannot be empty"
        case .offsiteusername:
            return "Remote username cannot be empty"
        case .notconnected:
            return "Not connected, cannot create task"
        case .offsiteserver:
            return "Remote servername cannot be empty"
        case .snapshotnum:
            return "Snapshotnum must be 1"
        case .rsyncversion2:
            return "Snapshot require rsync ver3.x"
        }
    }
}

struct AppendTask: PropogateError {
    var newtask: String
    var newlocalCatalog: String
    var newoffsiteCatalog: String
    var newdontaddtrailingbackslash: Bool = false
    // Can be nil
    var newoffsiteUsername: String?
    var newoffsiteServer: String?
    var newbackupID: String?
    // Use hiddenID for update
    var hiddenID: Int?

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingbackslash: Bool,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?)
    {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newdontaddtrailingbackslash = trailingbackslash
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
    }

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingbackslash: Bool,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?,
         _ updatedhiddenID: Int)
    {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newdontaddtrailingbackslash = trailingbackslash
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
        hiddenID = updatedhiddenID
    }
}

@MainActor
final class VerifyConfiguration: Connected, PropogateError {
    let archive: String = "--archive"
    let verbose: String = "--verbose"
    let compress: String = "--compress"
    let delete: String = "--delete"
    let eparam: String = "-e"
    let ssh: String = "ssh"

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
        newconfig.parameter4 = delete
        newconfig.parameter5 = eparam
        newconfig.parameter6 = ssh
        newconfig.dateRun = ""
        newconfig.hiddenID = data.hiddenID ?? -1

        if data.newlocalCatalog.hasSuffix("/") == false, data.newdontaddtrailingbackslash == false {
            var catalog = data.newlocalCatalog
            guard catalog.isEmpty == false else {
                let error = ValidateInputError.localcatalog
                propogateerror(error: error)
                return nil
            }
            catalog += "/"
            newconfig.localCatalog = catalog
        }
        if data.newoffsiteCatalog.hasSuffix("/") == false, data.newdontaddtrailingbackslash == false {
            var catalog = data.newoffsiteCatalog
            guard catalog.isEmpty == false else {
                let error = ValidateInputError.localcatalog
                propogateerror(error: error)
                return nil
            }
            catalog += "/"
            newconfig.offsiteCatalog = catalog
        }
        if data.newtask == SharedReference.shared.snapshot {
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
            propogateerror(error: error)
            return nil
        }
        // If validated and snapshottask create remote snapshotcatalog
        // Must be connected to create base remote snapshot catalog
        if data.newtask == SharedReference.shared.snapshot {
            // If connected create base remote snapshotcatalog
            snapshotcreateremotecatalog(config: newconfig)
        }
        // Return a new configuration to be appended
        return newconfig
    }

    // Create remote snapshot catalog
    private func snapshotcreateremotecatalog(config: SynchronizeConfiguration) {
        guard config.offsiteServer.isEmpty == false else { return }
        let args = SnapshotCreateCatalogArguments(config: config)
        let updatecurrent = CommandProcess(command: args.getCommand(),
                                           arguments: args.getArguments(),
                                           processtermination: processtermination)
        updatecurrent.executeProcess()
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
            if let rsyncversionshort = SharedReference.shared.rsyncversionshort {
                guard rsyncversionshort.contains("version 3") else {
                    Logger.process.warning("VerifyConfiguration: snapshots requiere version 3.x of rsync.")
                    throw ValidateInputError.rsyncversion2
                }
            }
            guard config.snapshotnum == 1 else {
                Logger.process.warning("VerifyConfiguration: snapshotnum not 1 (initial value).")
                throw ValidateInputError.snapshotnum
            }
            // also check if connected because creating base remote catalog if remote server
            // must be connected to create remote base catalog
            guard connected(server: config.offsiteServer) else {
                Logger.process.warning("VerifyConfiguration: not connected to remote server.")
                throw ValidateInputError.notconnected
            }
        }
        if config.task == SharedReference.shared.syncremote {
            guard config.offsiteServer.isEmpty == false, config.offsiteUsername.isEmpty == false else {
                throw ValidateInputError.offsiteusername
            }
        }
        return true
    }

    func processtermination(data _: [String]?) {}
}

// swiftlint:enable cyclomatic_complexity function_body_length
