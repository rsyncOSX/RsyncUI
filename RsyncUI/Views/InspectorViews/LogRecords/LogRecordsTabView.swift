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

    @State private var hiddenID = -1
    @State private var selectedloguuids = Set<Log.ID>()
    /// Alert for delete
    @State private var confirmdelete = false
    // Filterstring
    @State private var filterstring: String = ""
    @State private var showindebounce: Bool = false
    @State private var filterTask: Task<Void, Never>?
    @State private var reloadTask: Task<Void, Never>?

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
                .onChange(of: selecteduuids) {
                    if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                        hiddenID = configurations[index].hiddenID
                    } else {
                        hiddenID = -1
                    }
                    Task {
                        let actorreadlogs = ActorReadLogRecordsJSON()
                        if filterstring.isEmpty == false {
                            logs = await actorreadlogs.updatelogsbyfilter(logrecords, filterstring, hiddenID) ?? []
                        } else {
                            logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
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
                        Label("There are no logs by this filter", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for other filter in Date or Result")
                    }
                } else if showindebounce {
                    ContentUnavailableView {
                        Label("Sorting logs", systemImage: "doc.richtext.fill")
                    } description: {}
                }
                }
            }

            HStack {
                if showindebounce {
                    indebounce
                } else {
                    if selecteduuids.isEmpty {
                        let logText = logs.count == 1 ?
                            "ALL logrecords, select task for logrecords by task: 1 log" :
                            "ALL logrecords, select task for logrecords by task: \(logs.count) logs"
                        Text(logText)

                        if filterstring.isEmpty == false {
                            Label("Filtered by: \(filterstring)", systemImage: "magnifyingglass")
                        }
                    } else {
                        let logText = logs.count == 1 ?
                            "Logrecords by selected task: 1 log" :
                            "Logrecords by selected task: \(logs.count) logs"
                        Text(logText)

                        if filterstring.isEmpty == false {
                            Label("Filtered by: \(filterstring)", systemImage: "magnifyingglass")
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .searchable(if: selectedTab == .logview, text: $filterstring)
        .task {
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                hiddenID = configurations[index].hiddenID
            } else {
                hiddenID = -1
            }
            let actorreadlogs = ActorReadLogRecordsJSON()
            logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
            logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
        }
        .onChange(of: filterstring) {
            showindebounce = true
            filterTask?.cancel()
            filterTask = Task {
                try? await Task.sleep(seconds: 1)
                guard Task.isCancelled == false else { return }
                showindebounce = false
                let actorreadlogs = ActorReadLogRecordsJSON()
                if filterstring.isEmpty == false {
                    logs = await actorreadlogs.updatelogsbyfilter(logrecords, filterstring, hiddenID) ?? []
                } else {
                    logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
                }
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            reloadTask?.cancel()
            reloadTask = Task {
                logs = []
                logrecords = nil
                showindebounce = true
                try? await Task.sleep(seconds: 1)
                guard Task.isCancelled == false else { return }
                showindebounce = false
                selectedloguuids.removeAll()

                let actorreadlogs = ActorReadLogRecordsJSON()
                logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
                logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
            }
        }
        .toolbar(content: {
            if selectedTab == .logview {
                ToolbarItem {
                    Button {
                        selectedloguuids.removeAll()
                        selecteduuids.removeAll()
                    } label: {
                        Label("Reset selections", systemImage: "clear")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(selectedloguuids.count == 0 ? Color(.blue) : Color(.red))
                            .overlay(
                                Group {
                                    if selectedloguuids.count > 50 {
                                        // Show "50+" as text with proper sizing
                                        Text("50+")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(minWidth: 24, minHeight: 24)
                                            .background(Circle().fill(Color.red))
                                    } else if selectedloguuids.count > 0 {
                                        // Show number as SF Symbol
                                        Image(systemName: "\(selectedloguuids.count).circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                                .allowsHitTesting(false)
                                .offset(x: 10, y: -10)
                            )
                    }
                    .help("Reset selections")
                }
            }
        })
        .padding()
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
    }

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        if let configurations = rsyncUIdata.configurations {
            for config in configurations {
                temp.insert(config.hiddenID)
            }
        }
        return temp
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = rsyncUIdata.configurations {
            configurations
        } else {
            []
        }
    }

    func deleteLogs(_ uuids: Set<UUID>) async {
        async let updatedRecords: [LogRecords]? = ActorReadLogRecordsJSON().deleteLogs(
            uuids,
            logrecords: logrecords
        )
        let records = await updatedRecords
        async let updatedLogs: [Log]? = ActorReadLogRecordsJSON().updatelogsbyhiddenID(records, hiddenID)
        logrecords = records
        logs = await (updatedLogs ?? [])
        WriteLogRecordsJSON(rsyncUIdata.profile, records)
        selectedloguuids.removeAll()
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
