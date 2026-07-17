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
    var trailingslash = true
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

    /// THE BUG IS HERE
    func addConfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) async -> [SynchronizeConfiguration]? {
        let getdata = NewTask(selectedrsynccommand.rawValue,
                              localcatalog.replacingOccurrences(of: "\"", with: ""),
                              remotecatalog.replacingOccurrences(of: "\"", with: ""),
                              trailingslash,
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

        if snapshotnum.isEmpty == false {
            if Int(snapshotnum) != nil {
                mysnapshotnum = Int(snapshotnum) ?? 1
            }
        }

        // If toggled ON remove trailing / to be validated later
        if trailingslash {
            if localcatalog.hasSuffix("/") {
                localcatalog.removeLast()
            }
        }

        if localcatalog.hasSuffix("/") == false {
            trailingslash = false
        }

        guard let hiddenID = selectedconfig?.hiddenID else { return nil }
        let updateddata = NewTask(selectedrsynccommand.rawValue,
                                  localcatalog.replacingOccurrences(of: "\"", with: ""),
                                  remotecatalog.replacingOccurrences(of: "\"", with: ""),
                                  trailingslash,
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
            localcatalog = config.localCatalog
            remotecatalog = config.offsiteCatalog
            remoteuser = config.offsiteUsername
            remoteserver = config.offsiteServer
            backupID = config.backupID
            if config.task == SharedReference.shared.snapshot {
                if let num = config.snapshotnum {
                    snapshotnum = String(num)
                }
            }
        } else {
            selectedconfig = nil
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
