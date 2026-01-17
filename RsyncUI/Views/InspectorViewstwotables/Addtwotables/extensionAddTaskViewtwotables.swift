//
//  extensionAddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

// MARK: - Configuration Actions

extension AddTaskViewtwotables {
    func addConfig() {
        let profile = rsyncUIdata.profile
        rsyncUIdata.configurations = newdata.addConfig(profile, rsyncUIdata.configurations)
        if SharedReference.shared.duplicatecheck {
            if let configurations = rsyncUIdata.configurations {
                VerifyDuplicates(configurations)
            }
        }
    }

    func validateAndUpdate() {
        let profile = rsyncUIdata.profile
        rsyncUIdata.configurations = newdata.updateConfig(profile, rsyncUIdata.configurations)
        // Reset after Update
        clearSelection()
    }
}

// MARK: - Buttons

extension AddTaskViewtwotables {
    var updateButton: some View {
        ConditionalGlassButton(systemImage: "arrow.down", text: "Update", helpText: "Update task") {
            validateAndUpdate()
        }
    }

    var saveURLSection: some View {
        Section(header: Text("Show save URL").font(.title3).fontWeight(.bold)) {
            HStack {
                Toggle("", isOn: $newdata.showsaveurls).toggleStyle(.switch)
                if newdata.showsaveurls {
                    ConditionalGlassButton(systemImage: "square.and.arrow.down",
                                           text: "URL Estimate",
                                           helpText: "URL Estimate & Synchronize") {
                        let data = WidgetURLstrings(urletimate: stringestimate)
                        WriteWidgetsURLStringsJSON(data)
                    }
                }
            }
        }
    }
}
