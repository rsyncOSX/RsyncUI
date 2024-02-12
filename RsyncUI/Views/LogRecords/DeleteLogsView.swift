//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//

import SwiftUI

struct DeleteLogsView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var rsyncUIlogrecords: RsyncUIlogrecords
    @Binding var selectedloguuids: Set<UUID>

    var selectedprofile: String?

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") { delete() }
                    .buttonStyle(ColorfulRedButtonStyle())

                Button("Cancel") { dismiss() }
                    .buttonStyle(ColorfulButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Delete", comment: "")
                + " \(selectedloguuids.count) "
                + "log(s)?"
            Text(message)
                .font(.title2)
        }
        .padding()
    }

    func delete() {
        let deletelogs = UpdateLogs(profile: selectedprofile,
                                    logrecords: rsyncUIlogrecords.logrecords)
        rsyncUIlogrecords.logrecords = deletelogs.deletelogs(uuids: selectedloguuids)
        selectedloguuids.removeAll()
        dismiss()
    }
}

