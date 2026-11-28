//
//  extensionAddTaskView+ViewBuilders.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

// MARK: - View Builders

extension AddTaskView {
    var catalogSectionView: some View {
        Group {
            if newdata.selectedrsynccommand == .syncremote {
                localandremotecatalogsyncremote
            } else {
                localandremotecatalog
                    .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
            }
        }
    }

    var taskSummary: some View {
        Section("What this task will do") {
            switch newdata.selectedrsynccommand {
            case .synchronize:
                Label("Copy from the source folder to the destination.", systemImage: "arrow.right")
            case .snapshot:
                Label("Create a snapshot of the source at the destination.", systemImage: "clock.arrow.circlepath")
            case .syncremote:
                Label("Pull from the remote source into the local destination.", systemImage: "arrow.down.to.line")
            }
            if !newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty {
                let local = newdata.localcatalog
                let remote = newdata.remoteserver.isEmpty ? newdata.remotecatalog : "\(newdata.remoteserver):\(newdata.remotecatalog)"
                LabeledContent("From", value: newdata.selectedrsynccommand == .syncremote ? remote : local)
                LabeledContent("To", value: newdata.selectedrsynccommand == .syncremote ? local : remote)
            }
        }
    }

    var addTaskSheetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Add Task", systemImage: "folder.badge.plus")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Form {
                pickerselecttypeoftask
                synchronizeID
                catalogSectionView
                remoteuserandserver
                taskSummary
            }
            .formStyle(.grouped)

            if !requiredFieldsAreComplete {
                Label("Complete the required fields before adding this task.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(minWidth: 600)
        .onSubmit { handleSubmit() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    Task { @MainActor in
                        await addConfigAndDismiss()
                    }
                }
                .disabled(!requiredFieldsAreComplete || isAdding)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismissAddSheet()
                }
            }
        }
    }
}
