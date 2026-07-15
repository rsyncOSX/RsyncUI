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
        }
        .onChange(of: rsyncUIdata.configurations, initial: true) {
            guard let configurations = rsyncUIdata.configurations else { return }
            if !showAddPopover {
                showAddPopover = configurations.isEmpty
            }
        }
        .inspector(isPresented: .constant(true)) {
            InspectorView(rsyncUIdata: rsyncUIdata,
                          selecteduuids: $selecteduuids,
                          showAddPopover: $showAddPopover)
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
