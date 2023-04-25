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
            List(selection: $selectedlog) {
                ForEach(filteredlogrecords) { record in
                    LogRow(selecteduuids: $selecteduuids, logrecord: record)
                        .tag(record)
                }
                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
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
