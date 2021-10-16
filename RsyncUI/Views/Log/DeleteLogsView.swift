//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//

import SwiftUI

struct DeleteLogsView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @Binding var selecteduuids: Set<UUID>
    @Binding var isPresented: Bool
    @Binding var selectedprofile: String?
    @Binding var deleted: Bool

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())

                Button("Cancel") { dismissview() }
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

    func dismissview() {
        isPresented = false
    }

    func delete() {
        let deleteschedule = UpdateSchedules(profile: selectedprofile,
                                             scheduleConfigurations: logrecords.schedulesandlogs)
        deleteschedule.deletelogs(uuids: selecteduuids)
        selecteduuids.removeAll()
        deleted = true
        isPresented = false
    }
}
