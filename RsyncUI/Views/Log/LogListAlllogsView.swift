//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//

import SwiftUI

struct LogListAlllogsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    @State private var filterstring: String = ""
    // Alert for delete
    @State private var showAlertfordelete = false

    var body: some View {
        Form {
            List(selection: $selectedlog) {
                if let logs = rsyncUIdata.filterlogsorted {
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
        .searchable(text: $filterstring.onChange {
            rsyncUIdata.filter(filterstring)
        })
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(rsyncUIdata.filterlogsorted?.count ?? 0)"
    }
}

extension LogListAlllogsView {
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
        for i in 0 ..< (rsyncUIdata.filterlogsorted?.count ?? 0) {
            if let id = rsyncUIdata.filterlogsorted?[i].id {
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
