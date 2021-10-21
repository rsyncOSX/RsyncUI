//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//

import SwiftUI

struct LogListAlllogsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Binding var filterstring: String
    @Binding var deleted: Bool

    @StateObject private var logrecords = RsyncUIlogrecords()

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    // Alert for delete
    @State private var showAlertfordelete = false
    @State private var showloading = true

    var body: some View {
        Form {
            ZStack {
                List(selection: $selectedlog) {
                    if let logs = logrecords.filterlogs(filterstring) {
                        ForEach(logs) { record in
                            LogRow(selecteduuids: $selecteduuids, logrecord: record)
                                .tag(record)
                        }
                        .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                    }
                }
                .task {
                    if selectedprofile == nil {
                        selectedprofile = SharedReference.shared.defaultprofile
                    }
                    // Initialize the Stateobject
                    await logrecords.update(profile: selectedprofile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
                    showloading = false
                }

                if showloading { ProgressView() }
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
                                       selectedprofile: $selectedprofile,
                                       deleted: $deleted)
                    }
            }
        }
        .padding()
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(logrecords.filterlogs(filterstring)?.count ?? 0)"
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
        for i in 0 ..< (logrecords.filterlogs(filterstring)?.count ?? 0) {
            if let id = logrecords.filterlogs(filterstring)?[i].id {
                selecteduuids.insert(id)
            }
        }
    }

    func setuuidforselectedlog() {
        if let sel = selectedlog,
           let index = logrecords.filterlogs(filterstring)?.firstIndex(of: sel)
        {
            if let id = logrecords.filterlogs(filterstring)?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
