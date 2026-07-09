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
    @ViewBuilder
    func CatalogSection() -> some View {
        Group {
            if newdata.selectedrsynccommand == .syncremote {
                SyncRemoteFoldersSection()
            } else {
                FoldersSection()
                    .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
            }
        }
    }

    @ViewBuilder
    func AddTaskSheetView() -> some View {
        VStack {
            Text("Add Task")
                .font(.title2)

            Form {
                TaskTypePicker()
                TrailingSlashPicker()
                SynchronizeIDSection()
                CatalogSection()
                RemoteSection()
            }
            .formStyle(.grouped)
        }
        .padding()
        .frame(minWidth: 600)
        .onSubmit { handleSubmit() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    Task { @MainActor in
                        if await addConfig() {
                            showAddPopover = false
                        }
                    }
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showAddPopover = false
                }
            }
        }
    }
}
