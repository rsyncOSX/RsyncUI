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
    @Binding var filterstring: String

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    // Alert for delete
    @State private var showAlertfordelete = false

    var body: some View {
        Form {
            List(selection: $selectedlog) {
                if let logs = rsyncUIdata.filterlogrecords(filterstring) {
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
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(rsyncUIdata.filterlogrecords(filterstring)?.count ?? 0)"
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
        for i in 0 ..< (rsyncUIdata.filterlogrecords(filterstring)?.count ?? 0) {
            if let id = rsyncUIdata.filterlogrecords(filterstring)?[i].id {
                selecteduuids.insert(id)
            }
        }
    }

    func setuuidforselectedlog() {
        if let sel = selectedlog,
           let index = rsyncUIdata.filterlogrecords(filterstring)?.firstIndex(of: sel)
        {
            if let id = rsyncUIdata.filterlogrecords(filterstring)?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
