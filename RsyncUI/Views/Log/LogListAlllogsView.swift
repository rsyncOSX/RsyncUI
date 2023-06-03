//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//

import SwiftUI

struct LogListAlllogsView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @Binding var selectedprofile: String?
    @Binding var filterstring: String
    @Binding var focusselectlog: Bool

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    // Alert for delete
    @State private var showAlertfordelete = false
    @State private var showloading = true

    var body: some View {
        Form {
            Table(filteredlogrecords, selection: $selecteduuids) {
                TableColumn("Date") { data in
                    Text(data.date.localized_string_from_date())
                }

                TableColumn("Result") { data in
                    if let result = data.resultExecuted {
                        Text(result)
                    }
                }
            }

            Spacer()

            HStack {
                Text(numberoflogs)

                Spacer()

                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $showAlertfordelete) {
                        DeleteLogsView(selecteduuids: $selecteduuids,
                                       selectedprofile: $selectedprofile)
                    }
            }
            .padding()
        }
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(filteredlogrecords.count)"
    }

    var filteredlogrecords: [Log] {
        logrecords.filterlogs(filterstring) ?? []
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
        let filteredlogscount = logrecords.filterlogs(filterstring)?.count ?? 0
        let filteredlogs = logrecords.filterlogs(filterstring)
        for i in 0 ..< filteredlogscount {
            if let id = filteredlogs?[i].id {
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
