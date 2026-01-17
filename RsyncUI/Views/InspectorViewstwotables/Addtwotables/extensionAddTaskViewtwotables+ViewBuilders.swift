//
//  extensionAddTaskViewtwotables+ViewBuilders.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

// MARK: - View Builders

extension AddTaskViewtwotables {
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

    var helpSheetView: some View {
        switch newdata.whichhelptext {
        case 1: HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
        case 2: HelpView(text: newdata.helptext2, add: false, deleteparameterpresent: false)
        default: HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // Only show toolbar items when this tab is active
        if selectedTab == .edit {
            ToolbarItem {
                Button {
                    showinspector = false
                    newdata.resetForm()
                    selectedconfig = nil
                    showAddPopover.toggle()
                }
                label: { Image(systemName: "plus") }
                .help("Quick add task")
                .sheet(isPresented: $showAddPopover) { addTaskSheetView }
            }

            ToolbarItem {
                Spacer()
            }
        }
    }

    var addTaskSheetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Task").font(.headline)
            HStack {
                pickerselecttypeoftask
                trailingslash
            }

            synchronizeID
            catalogSectionView
            remoteuserandserver
            HStack {
                ConditionalGlassButton(systemImage: "plus",
                                       text: "Add",
                                       helpText: "Add task") {
                    addConfig()
                    showAddPopover = false
                    newdata.resetForm()
                }.disabled(!disableadd)
                Spacer()
                if #available(macOS 26.0, *) {
                    Button("Close", role: .close) {
                        showAddPopover = false
                    }
                    .buttonStyle(RefinedGlassButtonStyle())
                    .keyboardShortcut(.cancelAction)
                } else {
                    Button {
                        showAddPopover = false
                    } label: {
                        Image(systemName: "return")
                    }
                    .help("Close")
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .padding()
        .frame(minWidth: 600)
        .onSubmit { handleSubmit() }
    }

    var taskListView: some View {
        ListofTasksAddView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
            .onChange(of: selecteduuids) { handleSelectionChange() }
            .copyable(copyitems.filter { selecteduuids.contains($0.id) })
            .pasteDestination(for: CopyItem.self) { handlePaste($0) }
            validator: { $0.filter { $0.task != SharedReference.shared.snapshot } }
            .confirmationDialog(confirmationMessage, isPresented: $confirmcopyandpaste) {
                Button("Copy") { handleCopyConfirmation() }
            }
    }

    var confirmationMessage: String {
        let count = newdata.copyandpasteconfigurations?.count ?? 0
        return count == 1 ? "Copy 1 configuration" : "Copy \(count) configurations"
    }

    var inspectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                updateButton
                trailingslash
            }
            synchronizeID
            catalogSectionView
            VStack(alignment: .leading) { remoteuserandserver }
            if selectedconfig?.task == SharedReference.shared.snapshot {
                VStack(alignment: .leading) { snapshotnum }
            }
            saveURLSection
        }
    }
}
