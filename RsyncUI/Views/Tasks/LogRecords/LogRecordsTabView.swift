//
//  LogRecordsTabView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/01/2021.
//

import SwiftUI

@MainActor
struct LogRecordsTabView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var selectedloguuids = Set<Log.ID>()
    /// Alert for delete
    @State private var confirmdelete = false
    // Filterstring
    @State private var filterstring: String = ""
    @State private var showindebounce: Bool = false

    @State private var logrecords: [LogRecords]?
    @State private var logs: [Log] = []

    var body: some View {
        VStack {
            HStack {
                Table(logs, selection: $selectedloguuids) {
                    TableColumn("Date") { data in
                        Text(data.date.localized_string_from_date())
                    }

                    TableColumn("Result") { data in
                        if let result = data.resultExecuted {
                            Text(result)
                        }
                    }
                }
                .onDeleteCommand {
                    confirmdelete = true
                }
                .confirmationDialog(selectedloguuids.count == 1 ? "Delete 1 log" :
                    "Delete \(selectedloguuids.count) logs",
                    isPresented: $confirmdelete) {
                        Button("Delete", role: .destructive) {
                            Task {
                                await deleteLogs(selectedloguuids)
                            }
                        }
                }
                .overlay { if logs.count == 0 {
                    ContentUnavailableView {
                        Label("No log records match this filter", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try a different date or result filter.")
                    }
                } else if showindebounce {
                    ContentUnavailableView {
                        Label("Sorting logs", systemImage: "doc.richtext.fill")
                    } description: {}
                }
                }
            }

            LogRecordsFooterView(logsCount: logs.count,
                                 selectedUuidsIsEmpty: selecteduuids.isEmpty,
                                 filterString: filterstring,
                                 showInDebounce: showindebounce)
        }
        .searchable(if: selectedTab == .logview, text: $filterstring)
        .task(id: selecteduuids) { updateLogsForSelection() }
        .task(id: rsyncUIdata.profile) { await loadLogsForProfile() }
        .task(id: filterstring) { try? await Task.sleep(seconds: 1)
            guard !Task.isCancelled else { return }
            await updateLogsForFilter()
        }
        .padding()
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = rsyncUIdata.configurations {
            configurations
        } else {
            []
        }
    }

    func deleteLogs(_ uuids: Set<UUID>) async {
        let records = await LogStoreService.deleteLogs(
            uuids,
            profile: rsyncUIdata.profile,
            in: logrecords
        )
        logrecords = records
        logs = LogStoreService.visibleLogs(
            from: records,
            configurations: rsyncUIdata.configurations,
            configurationID: selecteduuids.first,
            filterString: filterstring
        )
        selectedloguuids.removeAll()
    }

    private func updateLogsForFilter() async {
        showindebounce = false
        logs = LogStoreService.visibleLogs(
            from: logrecords,
            configurations: rsyncUIdata.configurations,
            configurationID: selecteduuids.first,
            filterString: filterstring
        )
    }

    private func loadLogsForProfile() async {
        logs = []
        logrecords = nil
        showindebounce = true
        try? await Task.sleep(seconds: 1)
        guard Task.isCancelled == false else { return }
        showindebounce = false
        selectedloguuids.removeAll()

        logrecords = await LogStoreService.loadStore(
            profile: rsyncUIdata.profile,
            configurations: rsyncUIdata.configurations
        )
        logs = LogStoreService.visibleLogs(
            from: logrecords,
            configurations: rsyncUIdata.configurations,
            configurationID: selecteduuids.first,
            filterString: filterstring
        )
    }

    private func updateLogsForSelection() {
        logs = LogStoreService.visibleLogs(
            from: logrecords,
            configurations: rsyncUIdata.configurations,
            configurationID: selecteduuids.first,
            filterString: filterstring
        )
    }
}

/// 1. Create a custom modifier extension
extension View {
    @ViewBuilder
    func searchable(if condition: Bool, text: Binding<String>, prompt: String = "Search") -> some View {
        if condition {
            searchable(text: text, prompt: prompt)
        } else {
            self
        }
    }
}
