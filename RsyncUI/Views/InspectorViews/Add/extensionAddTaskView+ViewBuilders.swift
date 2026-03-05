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

    var helpSheetView: some View {
        switch newdata.whichhelptext {
        case 1: HelpView(text: newdata.helptext1)
        case 2: HelpView(text: newdata.helptext2)
        default: HelpView(text: newdata.helptext1)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // Only show toolbar items when this tab is active
        if selectedTab == .edit {
            ToolbarItem(placement: .navigation) {
                Button {
                    newdata.resetForm()
                    selectedconfig = nil
                    showAddPopover.toggle()
                }
                label: { Image(systemName: "plus") }
                .help("Quick add task")
                .sheet(isPresented: $showAddPopover) { addTaskSheetView }
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


}
