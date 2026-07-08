//
//  InspectorView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

enum InspectorTab: Hashable {
    case edit
    case parameters
    case logview
    case verifytask
}

struct InspectorView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var showAddPopover: Bool

    @State private var selectedTab: InspectorTab = .edit

    var body: some View {
        if selecteduuids.count == 0 {
            ZStack {
                AddTaskView(rsyncUIdata: rsyncUIdata,
                            selectedTab: $selectedTab,
                            selecteduuids: $selecteduuids,
                            showAddPopover: $showAddPopover)
                    .opacity(0)
                    .allowsHitTesting(false)

                Text("No task\nselected")
                    .font(.title2)
            }
        } else {
            VStack(spacing: 0) {
                Picker("Inspector Tab", selection: $selectedTab) {
                    Text("Edit").tag(InspectorTab.edit)
                    Text("Parameters").tag(InspectorTab.parameters)
                    Text("Logs").tag(InspectorTab.logview)
                    Text("Verify").tag(InspectorTab.verifytask)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                InspectorContentView(
                    rsyncUIdata: rsyncUIdata,
                    selectedTab: $selectedTab,
                    selecteduuids: $selecteduuids,
                    showAddPopover: $showAddPopover
                )
            }
            .navigationTitle("")
            .inspectorColumnWidth(min: 550, ideal: 600, max: 650)
        }
    }
}
