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
    @State private var isInspectorPresented: Bool = true

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
        .task(id: rsyncUIdata.configurations) {
            if rsyncUIdata.configurations == nil {
                showAddPopover = true
            } else if let config = rsyncUIdata.configurations, config.isEmpty {
                showAddPopover = true
            }
        }
        .inspector(isPresented: $isInspectorPresented) {
            InspectorView(rsyncUIdata: rsyncUIdata,
                          selecteduuids: $selecteduuids)
                .inspectorColumnWidth(min: 550, ideal: 600, max: 650)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showAddPopover) {
            AddTaskView(rsyncUIdata: rsyncUIdata,
                        selecteduuids: $selecteduuids,
                        mode: .add)
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
