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
    @State private var showNoTasks: Bool = false
    @State private var showAddPopover: Bool = false

    var body: some View {
        HStack {
            if showNoTasks {
                
                AddFirstTask(rsyncUIdata: rsyncUIdata)
                
            } else {
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
        }
        .task(id: rsyncUIdata.configurations) {
            if rsyncUIdata.configurations == nil {
                showNoTasks = true
            } else if let config = rsyncUIdata.configurations, config.isEmpty {
                showNoTasks = true
            } else {
                showNoTasks = false
            }
        }
        .inspector(isPresented: Binding(
            get: { !showNoTasks },
            set: { showNoTasks = !$0 }
        )) {
            InspectorView(rsyncUIdata: rsyncUIdata,
                          selecteduuids: $selecteduuids,
                          showAddPopover: $showAddPopover)
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                Button {
                    showAddPopover.toggle()
                } label: {
                    Label("Quick add task", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .help("Quick add task")
            }
        })
    }
}
