//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import SwiftUI

struct LogsbyConfigurationView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Binding var filterstring: String
    @Binding var focusselectlog: Bool

    @State private var selectedlog: Log?
    @State private var selectedlogsuuids = Set<UUID>()
    @State private var selecteduuids = Set<Configuration.ID>()
    @StateObject var selectedconfig = Selectedconfig()

    // Not used but requiered in parameter
    @State private var inwork = -1
    // Alert for delete
    @State private var showAlertfordelete = false

    @State private var reload: Bool = false
    @State private var confirmdelete: Bool = false

    let selectable = false

    var body: some View {
        Form {
            ListofTasksView(
                selecteduuids: $selecteduuids.onChange {
                    let selected = rsyncUIdata.configurations?.filter { config in
                        selecteduuids.contains(config.id)
                    }
                    if (selected?.count ?? 0) == 1 {
                        if let config = selected {
                            selectedconfig.config = config[0]
                        }
                    } else {
                        selectedconfig.config = nil
                    }
                },
                inwork: $inwork,
                filterstring: $filterstring,
                reload: $reload,
                confirmdelete: $confirmdelete
            )

            Spacer()

            List(selection: $selectedlog) {
                if let logs = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig.config?.hiddenID ?? -1) {
                    ForEach(logs) { record in
                        LogRow(selecteduuids: $selectedlogsuuids, logrecord: record)
                            .tag(record)
                    }
                    .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                }
            }

            if focusselectlog { labelselectlog }

            Spacer()

            HStack {
                Text(numberoflogs)

                Spacer()

                Button("Select") {
                    if selectedlogsuuids.count > 0 {
                        selectedlogsuuids.removeAll()
                    } else {
                        selectall()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $showAlertfordelete) {
                        DeleteLogsView(selecteduuids: $selectedlogsuuids,
                                       selectedprofile: $selectedprofile)
                    }
            }
        }
        .padding()
    }

    var labelselectlog: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusselectlog = false
                select()
            })
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(logrecords.filterlogsbyhiddenID(filterstring, selectedconfig.config?.hiddenID ?? -1)?.count ?? 0)"
    }
}

extension LogsbyConfigurationView {
    func delete() {
        if selectedlogsuuids.count == 0 {
            setuuidforselectedlog()
        }
        guard selectedlogsuuids.count > 0 else { return }
        showAlertfordelete = true
    }

    func select() {
        if let selectedlog = selectedlog {
            if selectedlogsuuids.contains(selectedlog.id) {
                selectedlogsuuids.remove(selectedlog.id)
            } else {
                selectedlogsuuids.insert(selectedlog.id)
            }
        }
    }

    func selectall() {
        selectedlogsuuids.removeAll()
        let filteredlogscount = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig.config?.hiddenID ?? -1)?.count ?? 0
        let filteredlogs = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig.config?.hiddenID ?? -1)
        for i in 0 ..< filteredlogscount {
            if let id = filteredlogs?[i].id {
                selectedlogsuuids.insert(id)
            }
        }
    }

    func setuuidforselectedlog() {
        if let sel = selectedlog,
           let index = logrecords.filterlogsbyhiddenID(filterstring,
                                                       selectedconfig.config?.hiddenID ?? -1)?.firstIndex(of: sel)
        {
            if let id = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig.config?.hiddenID ?? -1)?[index].id {
                selectedlogsuuids.insert(id)
            }
        }
    }
}

// swiftlint:enable line_length
