//
//  extensionAddTaskView+BusinessLogic.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

// MARK: - Business Logic & User Actions

extension AddTaskView {
    func clearSelection() {
        selecteduuids.removeAll()
        selectedconfig = nil
        newdata.updateview(nil)
        newdata.showsaveurls = false
        changesnapshotnum = false
        stringestimate = ""
    }

    func handleSubmit() {
        switch focusField {
        case .synchronizeIDField: focusField = .localcatalogField
        case .localcatalogField: focusField = .remotecatalogField
        case .remotecatalogField: focusField = .remoteuserField
        case .remoteuserField: focusField = .remoteserverField
        case .snapshotnumField: validateAndUpdate()
        case .remoteserverField:
            if newdata.selectedconfig == nil { addConfig() } else { validateAndUpdate() }
            focusField = nil
        default: return
        }
    }

    func handleProfileChange() {
        newdata.resetForm()
        selecteduuids.removeAll()
        selectedconfig = nil
    }

    func handleSelectionChange() {
        if let configurations = rsyncUIdata.configurations {
            guard selecteduuids.count == 1 else {

                return
            }
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                selectedconfig = configurations[index]
                newdata.updateview(configurations[index])
                updateURLString()

            } else {
                selectedconfig = nil
                newdata.updateview(nil)
                stringestimate = ""
                newdata.showsaveurls = false
            
            }
        }
    }

    func updateURLString() {
        if selectedconfig?.task == SharedReference.shared.synchronize {
            let deeplinkurl = DeeplinkURL()
            let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "Default")
            stringestimate = urlestimate?.absoluteString ?? ""
        } else {
            stringestimate = ""
        }
    }

    func loadTrailingSlashPreference() {
        if let value = UserDefaults.standard.value(forKey: "trailingslashoptions") as? String {
            newdata.trailingslashoptions = TrailingSlash(rawValue: value) ?? .add
        }
    }

    func loadRsyncCommandPreference() {
        if let value = UserDefaults.standard.value(forKey: "selectedrsynccommand") as? String {
            newdata.selectedrsynccommand = TypeofTask(rawValue: value) ?? .synchronize
        }
    }
}

// MARK: - Computed Properties

extension AddTaskView {
    /// The verify returns true when data is OK
    var disableadd: Bool {
        VerifyObservableAddConfiguration(observed: newdata).verify()
    }

    var deleteparameterpresent: Bool {
        (rsyncUIdata.configurations?.filter { $0.parameter4?.isEmpty == false }.count ?? 0) > 0
    }
}
