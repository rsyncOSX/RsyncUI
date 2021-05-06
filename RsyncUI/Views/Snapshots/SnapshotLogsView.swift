//
//  SnapshotLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/05/2021.
//

import SwiftUI

struct SnapshotLogsView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata

    @Binding var reload: Bool
    @Binding var selectedconfig: Configuration?
    @Binding var logs: Bool

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    @State private var filterstring: String = ""
    // Alert for delete
    @State private var showAlertfordelete = false

    var body: some View {
        Form {
            List(selection: $selectedlog) {
                if let logs = rsyncUIData.filterlogsortedbyother {
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
                                       selectedprofile: $rsyncUIData.profile)
                    }

                Button(NSLocalizedString("Return", comment: "Select button")) { logs = false }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(rsyncUIData.filterlogsortedbyother?.count ?? 0)"
    }
}

extension SnapshotLogsView {
    func delete() {
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
        for i in 0 ..< (rsyncUIData.filterlogsortedbyother?.count ?? 0) {
            if let id = rsyncUIData.filterlogsortedbyother?[i].id {
                selecteduuids.insert(id)
            }
        }
    }
}
