//
//  ObservableAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint:disable line_length

import Foundation
import Observation
import OSLog

enum TrailingSlash: String, CaseIterable, Identifiable, CustomStringConvertible {
    case add, do_not_add, do_not_check
    
    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@Observable @MainActor
final class ObservableAddConfigurations {
    
    var trailingslashoptions = TrailingSlash.add
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
    var localhome: String {
        Homepath().userHomeDirectoryPath ?? ""
    }

    var snapshotnum: String = ""
    var copyandpasteconfigurations: [SynchronizeConfiguration]?

    let helptext1 = "Red Synchronize ID means\n--delete parameter is ADDED\nTo REMOVE --delete parameter,\nselect Rsync parameters view\nto remove"
    let helptext2 = "To ADD --delete parameter\nselect Rsync parameters view\nto add"

    @ObservationIgnored var whichhelptext: Int = 1

    func addconfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog.replacingOccurrences(of: "\"", with: ""),
                                 remotecatalog.replacingOccurrences(of: "\"", with: ""),
                                 trailingslashoptions,
                                 remoteuser,
                                 remoteserver,
                                 backupID)
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            let updateconfigurations =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            if updateconfigurations.addconfiguration(newconfig) == true {
                resetform()
                return updateconfigurations.configurations
            }
        }
        return configurations
    }

    func updateconfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
        var mysnapshotnum = 0

        if snapshotnum.isEmpty == false {
            if Int(snapshotnum) != nil {
                mysnapshotnum = Int(snapshotnum) ?? 1
            }
        }
        
        // If toggled ON remove trailing /
        if trailingslashoptions == .do_not_add {
            if localcatalog.hasSuffix("/") {
                localcatalog.removeLast()
            }
            if remotecatalog.hasSuffix("/") {
                remotecatalog.removeLast()
            }
        }

        if localcatalog.hasSuffix("/") == false, remotecatalog.hasSuffix("/") == false {
            trailingslashoptions = .do_not_add
        }

        let updateddata = AppendTask(selectedrsynccommand.rawValue,
                                     localcatalog.replacingOccurrences(of: "\"", with: ""),
                                     remotecatalog.replacingOccurrences(of: "\"", with: ""),
                                     trailingslashoptions,
                                     remoteuser,
                                     remoteserver,
                                     backupID,
                                     selectedconfig?.hiddenID ?? -1,
                                     Int(mysnapshotnum))
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

    // Prepare for Copy and Paste tasks
    func preparecopyandpastetasks(_ items: [CopyItem], _ configurations: [SynchronizeConfiguration]) {
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

    // After accept of Copy and Paste a write operation is performed
    func writecopyandpastetasks(_ profile: String?, _ configurations: [SynchronizeConfiguration]) -> [SynchronizeConfiguration]? {
        let updateconfigurations =
            UpdateConfigurations(profile: profile,
                                 configurations: configurations)
        return updateconfigurations.writecopyandpastetask(copyandpasteconfigurations)
    }
}

// Compute max hiddenID as part of copy and paste function..
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

// swiftlint:enable line_length
