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
            .sheet(isPresented: $showAddPopover) { AddTaskSheetView(onAdd: onAdd) }


        }
        .task(id: rsyncUIdata.configurations) {
            if rsyncUIdata.configurations == nil {
                showAddPopover = true
            } else if let config = rsyncUIdata.configurations, config.isEmpty {
                showAddPopover = true
            }
        }
        .inspector(isPresented: .constant(true)) {
            InspectorView(rsyncUIdata: rsyncUIdata,
                          selecteduuids: $selecteduuids)
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
