//
//  EditTabView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

struct EditTabView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var showAddPopover: Bool = false

    @FocusState var focusField: AddConfigurationField?

    func handleSubmit(_ newdata: ObservableAddConfigurations) {
        switch focusField {
        case .synchronizeIDField: focusField = .localcatalogField
        case .localcatalogField: focusField = .remotecatalogField
        case .remotecatalogField: focusField = .remoteuserField
        case .remoteuserField: focusField = .remoteserverField
        case .snapshotnumField:
            Task { @MainActor in
                _ = await validateAndUpdate(newdata: newdata)
            }
        case .remoteserverField:
            if newdata.selectedconfig == nil {
                Task { @MainActor in
                    _ = await addConfig(newdata: newdata)
                }
            } else {
                Task { @MainActor in
                    _ = await validateAndUpdate(newdata: newdata)
                }
            }
            focusField = nil
        default: return
        }
    }

    @MainActor
    func validateAndUpdate(newdata: ObservableAddConfigurations) async -> Bool {
        let profile = rsyncUIdata.profile
        let selectedHiddenID = newdata.selectedconfig?.hiddenID
        rsyncUIdata.configurations = await newdata.updateConfig(profile, rsyncUIdata.configurations)
        return selectedHiddenID != nil && newdata.selectedconfig == nil
    }

    @MainActor
    func addConfig(newdata: ObservableAddConfigurations) async -> Bool {
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

    func onAdd(newdata: ObservableAddConfigurations) {
        Task { @MainActor in
            if await addConfig(newdata: newdata) {
                showAddPopover = false
            }
        }
    }

    var body: some View {
        HStack {
            // Shared task list table on the left
            ListofTasksAddView(
                rsyncUIdata: rsyncUIdata,
                selecteduuids: $selecteduuids
            )
            .frame(minWidth: 300)
            .onChange(of: rsyncUIdata.profile) {
                selecteduuids.removeAll()
            }
            .sheet(isPresented: $showAddPopover) { AddTaskSheetView(focusField: $focusField, onAdd: onAdd, onSubmit: handleSubmit) }
        }
        .onChange(of: rsyncUIdata.configurations, initial: true) {
            guard let configurations = rsyncUIdata.configurations else { return }
            if !showAddPopover {
                showAddPopover = configurations.isEmpty
            }
        }
        .inspector(isPresented: .constant(true)) {
            InspectorView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids, focusField: $focusField, validateAndUpdate: validateAndUpdate, handleSubmit: handleSubmit)
        }
        .toolbar(content: {
            ToolbarItem(placement: .status) {
                Button {
                    showAddPopover.toggle()
                } label: {
                    Label("Add Task", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .help("Add Task")
                }
                .help("Add new task")
            }
        })
    }
}
