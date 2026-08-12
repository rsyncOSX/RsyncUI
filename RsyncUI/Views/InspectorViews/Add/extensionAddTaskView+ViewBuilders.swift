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

    var addTaskSheetView: some View {
        VStack {
            Text("Add Task")
                .font(.title2)

            Form {
                pickerselecttypeoftask
                synchronizeID
                catalogSectionView
                remoteuserandserver
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
                        settrailingSlash(for: $newdata.localcatalog)
                        if await addConfig() {
                            dismissAddSheet()
                        }
                    }
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismissAddSheet()
                }
            }
        }
    }
}
