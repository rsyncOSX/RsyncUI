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
