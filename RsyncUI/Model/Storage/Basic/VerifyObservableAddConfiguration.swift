//
//  VerifyObservableAddConfiguration.swift
//  RsyncUI
//
//  Created by GitHub Copilot on 30/12/2025.
//

import Foundation
import OSLog
import ProcessCommand

@MainActor
struct VerifyObservableAddConfiguration: Connected {
    var observed: ObservableAddConfigurations

    // Validate current values from ObservableAddConfigurations. Returns true when input is valid.
    func verify() -> Bool {
        let snapshotvalue: Int? = {
            guard observed.snapshotnum.isEmpty == false else { return nil }
            return Int(observed.snapshotnum)
        }()

        let hiddenID: Int
        if let selectedConfig = observed.selectedconfig {
            hiddenID = selectedConfig.hiddenID
        } else {
            hiddenID = -1
        }

        let data = NewTask(observed.selectedrsynccommand.rawValue,
                           observed.localcatalog.replacingOccurrences(of: "\"", with: ""),
                           observed.remotecatalog.replacingOccurrences(of: "\"", with: ""),
                           observed.trailingslashoptions,
                           observed.remoteuser,
                           observed.remoteserver,
                           observed.backupID,
                           hiddenID,
                           snapshotvalue)

        var newconfig = SynchronizeConfiguration()
        newconfig.task = data.newtask
        newconfig.backupID = data.newbackupID ?? ""
        newconfig.localCatalog = data.newlocalCatalog
        newconfig.offsiteCatalog = data.newoffsiteCatalog
        newconfig.offsiteServer = data.newoffsiteServer ?? ""
        newconfig.offsiteUsername = data.newoffsiteUsername ?? ""
        newconfig.parameter4 = nil
        newconfig.dateRun = ""
        if let datahideenID = data.hiddenID {
            newconfig.hiddenID = datahideenID
        } else {
            newconfig.hiddenID = -1
        }
        guard data.newlocalCatalog.isEmpty == false else {
            return false
        }

        guard data.newoffsiteCatalog.isEmpty == false else {
            return false
        }

        newconfig.snapshotnum = (data.snapshotnum ?? 0) > 0 ? data.snapshotnum : nil

        handleTrailingSlash(data: data, newconfig: &newconfig)
        handleSnapshotAndSyncRemote(data: data, newconfig: &newconfig)

        return validateInput(config: newconfig)
    }

    private func handleTrailingSlash(data: NewTask, newconfig: inout SynchronizeConfiguration) {
        switch data.newtrailingslashoptions {
        case .do_not_add:
            newconfig.localCatalog = data.newlocalCatalog.hasSuffix("/") ?
                String(data.newlocalCatalog.dropLast()) : data.newlocalCatalog
            newconfig.offsiteCatalog = data.newoffsiteCatalog.hasSuffix("/") ?
                String(data.newoffsiteCatalog.dropLast()) : data.newoffsiteCatalog
        case .add:
            newconfig.localCatalog = data.newlocalCatalog.hasSuffix("/") ?
                data.newlocalCatalog : data.newlocalCatalog + "/"
            newconfig.offsiteCatalog = data.newoffsiteCatalog.hasSuffix("/") ?
                data.newoffsiteCatalog : data.newoffsiteCatalog + "/"
        case .do_not_check:
            newconfig.localCatalog = data.newlocalCatalog
            newconfig.offsiteCatalog = data.newoffsiteCatalog
        }
    }

    private func handleSnapshotAndSyncRemote(data: NewTask, newconfig: inout SynchronizeConfiguration) {
        if data.newtask == SharedReference.shared.snapshot, newconfig.snapshotnum == nil {
            newconfig.task = SharedReference.shared.snapshot
            newconfig.snapshotnum = 1
        }
        if data.newtask == SharedReference.shared.syncremote {
            newconfig.task = SharedReference.shared.syncremote
        }
    }

    private func validateInput(config: SynchronizeConfiguration) -> Bool {
        guard config.localCatalog.isEmpty == false,
              config.offsiteCatalog.isEmpty == false
        else {
            return false
        }
        if config.offsiteServer.isEmpty == false {
            guard config.offsiteUsername.isEmpty == false else {
                return false
            }
        }
        if config.offsiteUsername.isEmpty == false {
            guard config.offsiteServer.isEmpty == false else {
                return false
            }
        }

        if config.task == SharedReference.shared.snapshot {
            return validateSnapshotTask(config: config)
        }

        if config.task == SharedReference.shared.syncremote {
            return validateSyncRemoteTask(config: config)
        }
        return true
    }

    private func validateSnapshotTask(config: SynchronizeConfiguration) -> Bool {
        guard SharedReference.shared.rsyncversion3 else {
            Logger.process.warning("VerifyObservableAddConfiguration: snapshots requiere version 3.x of rsync.")
            return false
        }

        guard config.snapshotnum != nil else {
            Logger.process.warning("VerifyObservableAddConfiguration: snapshotnum not set.")
            return false
        }
        guard connected(server: config.offsiteServer) else {
            Logger.process.warning("VerifyObservableAddConfiguration: not connected to remote server.")
            return false
        }
        return true
    }

    private func validateSyncRemoteTask(config: SynchronizeConfiguration) -> Bool {
        guard SharedReference.shared.rsyncversion3 else {
            Logger.process.warning("VerifyObservableAddConfiguration: syncremote requiere version 3.x of rsync.")
            return false
        }

        guard config.offsiteServer.isEmpty == false, config.offsiteUsername.isEmpty == false else {
            return false
        }
        return true
    }
}
