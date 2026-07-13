//
//  extensionAddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

// MARK: - Configuration Actions

extension AddTaskView {
    @MainActor
    func addConfig() async -> Bool {
        let profile = rsyncUIdata.profile
        let beforeCount = rsyncUIdata.configurations?.count ?? 0
        rsyncUIdata.configurations = await newdata.addConfig(profile, rsyncUIdata.configurations)
        if SharedReference.shared.duplicatecheck {
            if let configurations = rsyncUIdata.configurations {
                VerifyDuplicates(configurations)
            }
        }
        return (rsyncUIdata.configurations?.count ?? 0) > beforeCount
    }

    @MainActor
    func validateAndUpdate() async -> Bool {
        let profile = rsyncUIdata.profile
        let selectedHiddenID = newdata.selectedconfig?.hiddenID
        rsyncUIdata.configurations = await newdata.updateConfig(profile, rsyncUIdata.configurations)
        let didUpdate = selectedHiddenID != nil && newdata.selectedconfig == nil
        if didUpdate {
            clearSelection()
        }
        return didUpdate
    }
}
