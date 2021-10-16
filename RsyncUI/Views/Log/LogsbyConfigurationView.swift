//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogsbyConfigurationView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @Binding var reload: Bool
    @Binding var selectedprofile: String?
    @Binding var filterstring: String

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
            ConfigurationsListNoSearch(selectedconfig: $selectedconfig.onChange {
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

            Spacer()

            HStack {
                Text(numberoflogs)

                Spacer()

                Button("Clear") { selecteduuids.removeAll() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Select") { select() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("All") { selectall() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $showAlertfordelete) {
                        DeleteLogsView(selecteduuids: $selecteduuids,
                                       isPresented: $showAlertfordelete,
                                       reload: $reload,
                                       selectedprofile: $selectedprofile)
                    }
            }
        }
        .padding()
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
        for i in 0 ..< (logrecords.filterlogsbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)?.count ?? 0) {
            if let id = logrecords.filterlogsbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)?[i].id {
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
