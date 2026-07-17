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
        newdata.updateview(nil)
        newdata.showsaveurls = false
        stringestimate = ""
    }

    func handleProfileChange() {
        newdata.resetForm()
        selecteduuids.removeAll()
    }

    func handleSelectionChange() {
        if let configurations = rsyncUIdata.configurations {
            guard selecteduuids.count == 1 else {
                return
            }
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                newdata.updateview(configurations[index])
                updateURLString()
            } else {
                newdata.updateview(nil)
                stringestimate = ""
                newdata.showsaveurls = false
            }
        }
    }

    func updateURLString() {
        if newdata.selectedconfig?.task == SharedReference.shared.synchronize {
            let deeplinkurl = DeeplinkURL()
            let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "Default")
            stringestimate = urlestimate?.absoluteString ?? ""
        } else {
            stringestimate = ""
        }
    }
}
