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
    }

    func handleSubmit() {
        switch focusField {
        case .synchronizeIDField: focusField = .localcatalogField
        case .localcatalogField: focusField = .remotecatalogField
        case .remotecatalogField: focusField = .remoteuserField
        case .remoteuserField: focusField = .remoteserverField
        case .snapshotnumField:
            Task { @MainActor in
                _ = await validateAndUpdate()
            }
        case .remoteserverField:
            if newdata.selectedconfig == nil {
                Task { @MainActor in
                    _ = await addConfig(newdata: newdata)
                }
            } else {
                Task { @MainActor in
                    _ = await validateAndUpdate()
                }
            }
            focusField = nil
        default: return
        }
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
            } else {
                newdata.updateview(nil)
                newdata.showsaveurls = false
            }
        }
    }
}
