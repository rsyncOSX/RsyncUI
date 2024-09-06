//
//  ObservableAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint:disable line_length

import Foundation
import Observation

enum CannotUpdateSnaphotsError: LocalizedError {
    case cannotupdate

    var errorDescription: String? {
        switch self {
        case .cannotupdate:
            "Only synchronize ID can be changed on a Snapshot task"
        }
    }
}

@Observable @MainActor
final class ObservableAddConfigurations: PropogateError {
    var localcatalog: String = ""
    var remotecatalog: String = ""
    var donotaddtrailingslash: Bool = false
    var remoteuser: String = ""
    var remoteserver: String = ""
    var backupID: String = ""
    var selectedrsynccommand = TypeofTask.synchronize
    var selectedprofile: String?

    var deleted: Bool = false
    var created: Bool = false

    var showAlertfordelete: Bool = false

    var assistremoteuser: String = ""
    var assistremoteserver: String = ""

    // Set true if remote storage is a local attached Volume
    var remotestorageislocal: Bool = false
    var selectedconfig: SynchronizeConfiguration?
    var localhome: String {
        Homepath().userHomeDirectoryPath ?? ""
    }

    var copyandpasteconfigurations: [SynchronizeConfiguration]?

    func addconfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 donotaddtrailingslash,
                                 remoteuser,
                                 remoteserver,
                                 backupID)
        // If newconfig is verified add it
        if var newconfig = VerifyConfiguration().verify(getdata) {
            let updateconfigurations =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            newconfig.profile = selectedprofile
            if updateconfigurations.addconfiguration(newconfig) == true {
                resetform()
                return updateconfigurations.configurations
            }
        }
        return configurations
    }

    func updateconfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
        let updateddata = AppendTask(selectedrsynccommand.rawValue,
                                     localcatalog,
                                     remotecatalog,
                                     donotaddtrailingslash,
                                     remoteuser,
                                     remoteserver,
                                     backupID,
                                     selectedconfig?.hiddenID ?? -1)
        if let updatedconfig = VerifyConfiguration().verify(updateddata) {
            let updateconfigurations =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            updateconfigurations.updateconfiguration(updatedconfig, false)
            resetform()
            return updateconfigurations.configurations
        }
        return configurations
    }

    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        donotaddtrailingslash = false
        remoteuser = ""
        remoteserver = ""
        backupID = ""
        selectedconfig = nil
    }

    func validateandupdate(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
        do {
            // Validate not a snapshot task
            let validated = try validatenotsnapshottask()
            if validated {
                return updateconfig(profile, configurations)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return nil
        }
        return configurations
    }

    func updateview(_ config: SynchronizeConfiguration?) {
        selectedconfig = config
        if let config = selectedconfig {
            localcatalog = config.localCatalog
            remotecatalog = config.offsiteCatalog
            remoteuser = config.offsiteUsername
            remoteserver = config.offsiteServer
            backupID = config.backupID
        } else {
            selectedconfig = nil
            localcatalog = ""
            remotecatalog = ""
            remoteuser = ""
            remoteserver = ""
            backupID = ""
        }
    }

    private func validatenotsnapshottask() throws -> Bool {
        if let config = selectedconfig {
            if config.task == SharedReference.shared.snapshot {
                throw CannotUpdateSnaphotsError.cannotupdate
            } else {
                return true
            }
        }
        return false
    }

    func verifyremotestorageislocal() -> Bool {
        let fm = FileManager.default
        return fm.locationExists(at: remotecatalog, kind: .folder)
    }

    // Prepare for Copy and Paste tasks
    func preparecopyandpastetasks(_ items: [CopyItem], _ configurations: [SynchronizeConfiguration]) {
        copyandpasteconfigurations = nil
        copyandpasteconfigurations = [SynchronizeConfiguration]()
        let copyitems = configurations.filter { config in
            items.contains { item in
                item.id == config.id
            }
        }
        let existingmaxhiddenID = MaxhiddenID().computemaxhiddenID(configurations)
        for i in 0 ..< copyitems.count {
            var copy: SynchronizeConfiguration?
            copy = copyitems[i]
            copy?.backupID = "COPY: " + copyitems[i].backupID
            copy?.dateRun = nil
            copy?.hiddenID = existingmaxhiddenID + 1 + i
            copy?.id = UUID()
            if let copy {
                copyandpasteconfigurations?.append(copy)
            }
        }
    }

    // After accept of Copy and Paste a write operation is performed
    func writecopyandpastetasks(_ profile: String?, _ configurations: [SynchronizeConfiguration]) -> [SynchronizeConfiguration]? {
        let updateconfigurations =
            UpdateConfigurations(profile: profile,
                                 configurations: configurations)
        updateconfigurations.writecopyandpastetask(copyandpasteconfigurations)
        return updateconfigurations.configurations
    }
}

// Compute max hiddenID as part of copy and paste function..
struct MaxhiddenID {
    func computemaxhiddenID(_ configurations: [SynchronizeConfiguration]?) -> Int {
        // Reading Configurations from memory
        if let configs = configurations {
            var setofhiddenIDs = Set<Int>()
            // Fill set with existing hiddenIDS
            for i in 0 ..< configs.count {
                setofhiddenIDs.insert(configs[i].hiddenID)
            }
            return setofhiddenIDs.max() ?? 0
        }
        return 0
    }
}

// swiftlint:enable line_length
