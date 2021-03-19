//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct LogListAlllogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    @State private var filterstring: String = ""
    // Alert for delete
    @State private var showAlertfordelete = false

    var body: some View {
        Form {
            SearchbarView(text: $filterstring)
                .padding(.top, -20)

            List(selection: $selectedlog) {
                if let logs = filteredlogs {
                    ForEach(logs) { record in
                        LogRow(selecteduuids: $selecteduuids, logrecord: record)
                            .tag(record)
                    }
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

    var filteredlogs: [Log]? {
        // Important - must localize search in dates
        rsyncOSXData.alllogssorted?.filter {
            filterstring.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filterstring) ?? false ||
                filterstring.isEmpty ? true : $0.resultExecuted?.contains(filterstring) ?? false
        }
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(filteredlogs?.count ?? 0)"
    }
}

extension LogListAlllogsView {
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
        for i in 0 ..< (filteredlogs?.count ?? 0) {
            if let id = filteredlogs?[i].id {
                selecteduuids.insert(id)
            }
        }
    }
}
