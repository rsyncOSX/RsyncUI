//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogsbyConfigurationView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    @State private var selectedconfig: Configuration?
    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    @State private var filterstring: String = ""
    // Not used but requiered in parameter
    @State private var inwork = -1
    // Alert for delete
    @State private var showAlertfordelete = false

    let selectable = false

    var body: some View {
        Form {
            SearchbarView(text: $filterstring.onChange {
                rsyncUIdata.filterbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)
            })
                .padding(.top, -20)
            ConfigurationsList(selectedconfig: $selectedconfig.onChange {
                selecteduuids.removeAll()
                rsyncUIdata.filterbyhiddenID(filterstring, selectedconfig?.hiddenID ?? -1)
            },
            selecteduuids: $selecteduuids,
            inwork: $inwork,
            selectable: selectable)

            Spacer()

            List(selection: $selectedlog) {
                if let logs = rsyncUIdata.filterlogsortedbyother {
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

                Button(NSLocalizedString("Clear", comment: "Select button")) { selecteduuids.removeAll() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("All", comment: "Select button")) { selectall() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Delete", comment: "Delete button")) { delete() }
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
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(rsyncUIdata.filterlogsortedbyother?.count ?? 0)"
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
        for i in 0 ..< (rsyncUIdata.filterlogsortedbyother?.count ?? 0) {
            if let id = rsyncUIdata.filterlogsortedbyother?[i].id {
                selecteduuids.insert(id)
            }
        }
    }

    func setuuidforselectedlog() {
        if let sel = selectedlog,
           let index = rsyncUIdata.filterlogsorted?.firstIndex(of: sel)
        {
            if let id = rsyncUIdata.filterlogsorted?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
