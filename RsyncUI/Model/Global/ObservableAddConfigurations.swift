//
//  ObservableAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//

import Foundation
import Observation
import OSLog

@Observable @MainActor
final class ObservableAddConfigurations {
    var selectedrsynccommand = TypeofTask.synchronize

    var localcatalog: String = ""
    var remotecatalog: String = ""
    var remoteuser: String = ""
    var remoteserver: String = ""
    var backupID: String = ""

    var deleted: Bool = false
    var created: Bool = false
    var showAlertfordelete: Bool = false
    var selectedconfig: SynchronizeConfiguration?

    var snapshotnum: String = ""
    var copyandpasteconfigurations: [SynchronizeConfiguration]?

    var showsaveurls: Bool = false

    func addConfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) async -> [SynchronizeConfiguration]? {
        let getdata = NewTask(selectedrsynccommand.rawValue,
                              localcatalog.replacingOccurrences(of: "\"", with: ""),
                              remotecatalog.replacingOccurrences(of: "\"", with: ""),
                              remoteuser,
                              remoteserver,
                              backupID)
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            let updateconfigurations =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            if await updateconfigurations.addConfiguration(newconfig) == true {
                resetForm()
                return updateconfigurations.configurations
            }
        }
        return configurations
    }

    func updateConfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) async -> [SynchronizeConfiguration]? {
        var mysnapshotnum = 0

        if snapshotnum.isEmpty == false, Int(snapshotnum) != nil {
            mysnapshotnum = Int(snapshotnum) ?? 1
        }

        guard let hiddenID = selectedconfig?.hiddenID else { return nil }
        let updateddata = NewTask(selectedrsynccommand.rawValue,
                                  localcatalog.replacingOccurrences(of: "\"", with: ""),
                                  remotecatalog.replacingOccurrences(of: "\"", with: ""),

                                  remoteuser,
                                  remoteserver,
                                  backupID,
                                  hiddenID,
                                  Int(mysnapshotnum))

        if let updatedconfig = VerifyConfiguration().verify(updateddata) {
            let updateconfigurations =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            await updateconfigurations.updateConfiguration(updatedconfig, false)
            resetForm()
            return updateconfigurations.configurations
        }
        return configurations
    }

    /// True if the form differs from the task being edited
    var hasUnsavedChanges: Bool {
        guard let config = selectedconfig else { return false }
        if localcatalog.replacingOccurrences(of: "\"", with: "") != config.localCatalog ||
            remotecatalog.replacingOccurrences(of: "\"", with: "") != config.offsiteCatalog ||
            remoteuser != config.offsiteUsername ||
            remoteserver != config.offsiteServer ||
            backupID != config.backupID {
            return true
        }
        return config.task == SharedReference.shared.snapshot &&
            snapshotnum != (config.snapshotnum.map(String.init) ?? "")
    }

    /// The source of a remote pull is the remote folder, otherwise it is the local folder.
    func applyTrailingSlashToSource(enabled: Bool) {
        if selectedrsynccommand == .syncremote {
            remotecatalog = QuickTaskSourcePath.applyingTrailingSlash(to: remotecatalog, enabled: enabled)
        } else {
            localcatalog = QuickTaskSourcePath.applyingTrailingSlash(to: localcatalog, enabled: enabled)
        }
    }

    func resetForm() {
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
        backupID = ""
        selectedconfig = nil
        snapshotnum = ""
    }

    func updateview(_ config: SynchronizeConfiguration?) {
        selectedconfig = config
        if let config = selectedconfig {
            selectedrsynccommand = TypeofTask(rawValue: config.task) ?? .synchronize
            localcatalog = config.localCatalog
            remotecatalog = config.offsiteCatalog
            remoteuser = config.offsiteUsername
            remoteserver = config.offsiteServer
            backupID = config.backupID
            if config.task == SharedReference.shared.snapshot, let num = config.snapshotnum {
                snapshotnum = String(num)
            }
        } else {
            selectedrsynccommand = .synchronize
            localcatalog = ""
            remotecatalog = ""
            remoteuser = ""
            remoteserver = ""
            backupID = ""
            snapshotnum = ""
        }
    }

    /// Prepare for Copy and Paste tasks
    func prepareCopyAndPasteTasks(_ items: [CopyItem], _ configurations: [SynchronizeConfiguration]) {
        copyandpasteconfigurations = nil
        copyandpasteconfigurations = [SynchronizeConfiguration]()
        let copyitems = configurations.filter { config in
            items.contains { item in
                item.id == config.id
            }
        }
        var existingmaxhiddenID = MaxhiddenID().computemaxhiddenID(configurations)
        copyandpasteconfigurations = copyitems.map { record in
            var copy: SynchronizeConfiguration
            copy = record
            copy.backupID = "COPY: " + record.backupID
            copy.dateRun = nil
            copy.hiddenID = existingmaxhiddenID + 1
            copy.id = UUID()
            existingmaxhiddenID += 1
            return copy
        }
    }

    /// After accept of Copy and Paste a write operation is performed
    func writeCopyAndPasteTasks(
        _ profile: String?,
        _ configurations: [SynchronizeConfiguration]
    ) async -> [SynchronizeConfiguration]? {
        let updateconfigurations =
            UpdateConfigurations(profile: profile,
                                 configurations: configurations)
        return await updateconfigurations.writeCopyAndPasteTask(copyandpasteconfigurations)
    }
}

/// Compute max hiddenID as part of copy and paste function..
struct MaxhiddenID {
    func computemaxhiddenID(_ configurations: [SynchronizeConfiguration]?) -> Int {
        if let configs = configurations {
            var setofhiddenIDs = Set<Int>()
            _ = configs.map { record in
                setofhiddenIDs.insert(record.hiddenID)
            }
            return setofhiddenIDs.max() ?? 0
        }
        return 0
    }
}
