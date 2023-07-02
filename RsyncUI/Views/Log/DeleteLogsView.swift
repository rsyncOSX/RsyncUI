//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct DeleteLogsView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @SwiftUI.Environment(\.dismiss) var dismiss
    @Binding var selecteduuids: Set<UUID>
    @Binding var selectedprofile: String?

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())

                Button("Cancel") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Delete", comment: "")
                + " \(selecteduuids.count) "
                + "log(s)?"
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func delete() {
        logrecords.removerecords(selecteduuids)
        let deleteschedule = UpdateLogs(profile: selectedprofile,
                                        scheduleConfigurations: logrecords.scheduleConfigurations)
        deleteschedule.deletelogs(uuids: selecteduuids)
        selecteduuids.removeAll()
        dismiss()
    }
}

// swiftlint:enable line_length
