//
//  InspectorContentView.swift
//  RsyncUI
//
//  Created by Codex on 11/05/2026.
//

import SwiftUI

struct InspectorContentView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var showAddPopover: Bool

    var body: some View {
        switch selectedTab {
        case .edit:
            ScrollView {
                AddTaskView(rsyncUIdata: rsyncUIdata,
                            selectedTab: $selectedTab,
                            selecteduuids: $selecteduuids,
                            showAddPopover: $showAddPopover)
            }
        case .parameters:
            ScrollView {
                RsyncParametersView(rsyncUIdata: rsyncUIdata,
                                    selectedTab: $selectedTab,
                                    selecteduuids: $selecteduuids)
            }
        case .logview:
            LogRecordsTabView(
                rsyncUIdata: rsyncUIdata,
                selectedTab: $selectedTab,
                selecteduuids: $selecteduuids
            )
        case .verifytask:
            ScrollView {
                VerifyTaskTabView(
                    rsyncUIdata: rsyncUIdata,
                    selectedTab: $selectedTab,
                    selecteduuids: $selecteduuids
                )
            }
        }
    }
}
