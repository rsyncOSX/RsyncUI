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

    var body: some View {
        Form {
            SearchbarView(text: $filterstring)
                .padding(.top, -20)

            List(selection: $selectedlog) {
                ForEach(rsyncOSXData.alllogssorted?.filter { filterstring.isEmpty ? true : $0.dateExecuted?.contains(filterstring) ?? false } ?? []) { record in
                    LogRow(selecteduuids: $selecteduuids, logrecord: record)
                        .tag(record)
                }
            }

            Spacer()

            HStack {
                Text(label)

                Spacer()

                Button(NSLocalizedString("Clear", comment: "Select button")) { selecteduuids.removeAll() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("All", comment: "Select button")) { selectall() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Delete", comment: "Delete button")) { delete() }
                    .buttonStyle(AbortButtonStyle())
            }
        }
        .padding()
    }

    var label: String {
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(rsyncOSXData.alllogssorted?.count ?? 0)"
    }
}

extension LogListAlllogsView {
    func delete() {
        _ = NotYetImplemented()
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
        for i in 0 ..< (rsyncOSXData.alllogssorted?.count ?? 0) {
            if filterstring.isEmpty == true {
                if let id = rsyncOSXData.alllogssorted?[i].id {
                    selecteduuids.insert(id)
                }
            } else {
                if rsyncOSXData.alllogssorted?[i].dateExecuted?.contains(filterstring) ?? false {
                    if let id = rsyncOSXData.alllogssorted?[i].id {
                        selecteduuids.insert(id)
                    }
                }
            }
        }
    }
}
