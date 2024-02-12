//
//  LogsbyConfigurationView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import Combine
import SwiftUI

struct LogsbyConfigurationView: View {
    // @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var rsyncUIlogrecords: RsyncUIlogrecords

    @State private var hiddenID = -1
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedloguuids = Set<Log.ID>()
    // Alert for delete
    @State private var showAlertfordelete = false
    // Filterstring
    @State private var filterstring: String = ""
    @State var publisher = PassthroughSubject<String, Never>()
    @State private var debouncefilterstring: String = ""
    @State private var showindebounce: Bool = false

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack {
            HStack {
                ListofTasksLightView(selecteduuids: $selecteduuids,
                                     profile: profile,
                                     configurations: configurations)
                    .onChange(of: selecteduuids) {
                        let selected = configurations.filter { config in
                            selecteduuids.contains(config.id)
                        }
                        if selected.count == 1 {
                            hiddenID = selected[0].hiddenID

                        } else {
                            hiddenID = -1
                        }
                    }

                /* Table(rsyncUIlogrecords.filterlogs(debouncefilterstring, hiddenID),
                 selection: $selectedloguuids)*/

                Table(logs) {
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
                    showAlertfordelete = true
                }
                .overlay { if logs.count == 0 {
                    ContentUnavailableView {
                        Label("There are no logs by this filter", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for other filter in Date or Result")
                    }
                }
                }
            }
            HStack {
                Text("Number of log records: ")

                if showindebounce {
                    indebounce
                } else {
                    Text("\(logs.count)")
                }
                Spacer()
            }
        }
        .searchable(text: $filterstring)
        .onChange(of: filterstring) {
            showindebounce = true
            publisher.send(filterstring)
        }
        .onReceive(
            publisher.debounce(
                for: .seconds(1),
                scheduler: DispatchQueue.main
            )
        ) { filter in
            showindebounce = false
            debouncefilterstring = filter
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                    selecteduuids.removeAll()

                } label: {
                    Image(systemName: "clear")
                }
                .help("Reset selections")
            }
        })
        .sheet(isPresented: $showAlertfordelete) {
            DeleteLogsView(
                rsyncUIlogrecords: rsyncUIlogrecords,
                selectedloguuids: $selectedloguuids,
                selectedprofile: profile
            )
        }
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
    }

    // TODO: fix filter and by hiddenID
    var logs: [Log] {
        if let logrecords = rsyncUIlogrecords.logrecords {
            if hiddenID == -1 {
                var merged = [Log]()
                for i in 0 ..< logrecords.count {
                    merged = [merged + (logrecords[i].logrecords ?? [])].flatMap { $0 }
                }
                return merged
            }
            return []
        }
        return []
    }
}

/*
    func filterlogs(_ filter: String, _ hiddenID: Int) -> [Log] {
        var activelogrecords: [Log]?
        switch hiddenID {
        case -1:
            if filter.isEmpty == false {
                activelogrecords = nil
                activelogrecords = alllogssorted?.filter {
                    $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                        $0.resultExecuted?.contains(filter) ?? false
                }
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter ALL logs by \(filter, privacy: .public) - count: \(String(number), privacy: .public)")
                countrecords = number
                return activelogrecords ?? []

            } else {
                let number = alllogssorted?.count ?? 0
                Logger.process.info("ALL logs - count: \(String(number), privacy: .public)")
                countrecords = number
                return alllogssorted ?? []
            }
        default:
            if filter.isEmpty == false {
                activelogrecords = alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >).filter {
                    $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                        $0.resultExecuted?.contains(filter) ?? false
                }
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter logs BY hiddenID and filter by \(filter) - count: \(String(number), privacy: .public)")
                countrecords = number
                return activelogrecords ?? []
            } else {
                activelogrecords = nil
                activelogrecords = alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >)
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter logs BY hiddenID - count: \(String(number), privacy: .public)")
                countrecords = number
                return activelogrecords ?? []
            }
        }
    }

    func removerecords(_ uuids: Set<UUID>) {
        alllogssorted?.removeAll(where: { uuids.contains($0.id) })
    }
 */
