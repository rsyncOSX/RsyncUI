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
                VStack(alignment: .leading) { localandremotecatalogsyncremote }
            } else {
                VStack(alignment: .leading) { localandremotecatalog }
                    .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
            }
        }
    }

    var addTaskSheetView: some View {
        VStack {
            Text("Add Task").font(.title2)

            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    pickerselecttypeoftask
                    trailingslash
                }

                synchronizeID
                catalogSectionView
                remoteuserandserver
            }
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
