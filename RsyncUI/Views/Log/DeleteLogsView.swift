//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct DeleteLogsView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @Binding var selecteduuids: Set<UUID>
    var selectedprofile: String?
    var logrecords: RsyncUIlogrecords

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
        /*
         .toolbar(content: {
             ToolbarItem(placement: .cancellationAction) {
                 Button {
                     dismiss()
                 } label: {
                     Image(systemName: "xmark.circle")
                 }
                 .tooltip("Dismiss")
             }

             ToolbarItem(placement: .primaryAction) {
                 Button {
                     delete()
                 } label: {
                     Image(systemName: "trash")
                 }
                 .tooltip("Delete selected logs")
             }
         })
          */
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
