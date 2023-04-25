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
    @Binding var selectedprofile: String?
    @Binding var filterstring: String
    @Binding var focusselectlog: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()

    // Not used but requiered in parameter
    @State private var inwork = -1
    // Alert for delete
    @State private var showAlertfordelete = false

    let selectable = false

    var body: some View {
        Form {
            ListofAllTasks(selectedconfig: $selectedconfig.onChange {
                selecteduuids.removeAll()
            })

            Spacer()

            List(selection: $selectedlog) {
                if let logs = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1) {
                    ForEach(logs) { record in
                        LogRow(selecteduuids: $selecteduuids, logrecord: record)
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
                    if selecteduuids.count > 0 {
                        selecteduuids.removeAll()
                    } else {
                        selectall()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $showAlertfordelete) {
                        DeleteLogsView(selecteduuids: $selecteduuids,
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
            "\(logrecords.filterlogsbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)?.count ?? 0)"
    }
}

extension LogsbyConfigurationView {
    func delete() {
        if selecteduuids.count == 0 {
            setuuidforselectedlog()
        }
        guard selecteduuids.count > 0 else { return }
        showAlertfordelete = true
    }

    func select() {
        if let selectedlog = selectedlog {
            if selecteduuids.contains(selectedlog.id) {
                selecteduuids.remove(selectedlog.id)
            } else {
                selecteduuids.insert(selectedlog.id)
            }
        }
    }

    func selectall() {
        selecteduuids.removeAll()
        let filteredlogscount = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)?.count ?? 0
        let filteredlogs = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)
        for i in 0 ..< filteredlogscount {
            if let id = filteredlogs?[i].id {
                selecteduuids.insert(id)
            }
        }
    }

    func setuuidforselectedlog() {
        if let sel = selectedlog,
           let index = logrecords.filterlogsbyhiddenID(filterstring,
                                                       selectedconfig?.hiddenID ?? -1)?.firstIndex(of: sel)
        {
            if let id = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
