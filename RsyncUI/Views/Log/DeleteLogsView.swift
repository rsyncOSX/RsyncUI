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

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") {
                    Task {
                        await delete()
                    }
                }
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

    func delete() async {
        /*
         let deleteschedule = UpdateLogs(profile: selectedprofile,
                                         scheduleConfigurations: logrecords.schedulesandlogs)
         deleteschedule.deletelogs(uuids: selecteduuids)
         */

        await logrecords.removerecords(selecteduuids)
        selecteduuids.removeAll()
        isPresented = false
    }
}
