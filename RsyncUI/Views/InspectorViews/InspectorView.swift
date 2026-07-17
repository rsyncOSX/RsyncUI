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

    @FocusState.Binding var focusField: AddConfigurationField?

    @State private var selectedTab: InspectorTab = .edit

    let validateAndUpdate: (ObservableAddConfigurations) async -> Bool
    let handleSubmit: (ObservableAddConfigurations) -> Void

    var body: some View {
        if selecteduuids.count == 0 {
            ZStack {
                AddTaskView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids, focusField: $focusField, validateAndUpdate: validateAndUpdate, handleSubmit: handleSubmit)
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
                .labelsHidden()
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                switch selectedTab {
                case .edit:
                    ScrollView {
                        AddTaskView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids, focusField: $focusField, validateAndUpdate: validateAndUpdate, handleSubmit: handleSubmit)
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
            .navigationTitle("")
            .inspectorColumnWidth(min: 550, ideal: 600, max: 650)
        }
    }
}
