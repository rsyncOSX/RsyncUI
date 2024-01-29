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
    @Bindable var rsyncUIdata: RsyncUIconfigurations
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

    var body: some View {
        VStack {
            HStack {
                ListofTasksLightView(rsyncUIdata: rsyncUIdata,
                                     selecteduuids: $selecteduuids)
                    .onChange(of: selecteduuids) {
                        let selected = rsyncUIdata.configurations?.filter { config in
                            selecteduuids.contains(config.id)
                        }
                        if (selected?.count ?? 0) == 1 {
                            if let config = selected {
                                hiddenID = config[0].hiddenID
                            }
                        } else {
                            hiddenID = -1
                        }
                    }

                Table(rsyncUIlogrecords.filterlogs(debouncefilterstring, hiddenID),
                      selection: $selectedloguuids)
                {
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
                .overlay { if rsyncUIlogrecords.countrecords == 0 {
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
                    Text("\(rsyncUIlogrecords.countrecords)")
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
                selectedprofile: rsyncUIdata.profile
            )
        }
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
    }
}
