//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//

import SwiftUI

struct LogListAlllogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        Form {
            List(selection: $selectedlog) {
                ForEach(rsyncOSXData.alllogssorted ?? []) { record in
                    LogRow(selecteduuids: $selecteduuids, logrecord: record)
                        .tag(record)
                }
            }

            Spacer()

            HStack {
                Text(label)

                Spacer()

                Button(NSLocalizedString("Select", comment: "Select button")) { select() }
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
}
