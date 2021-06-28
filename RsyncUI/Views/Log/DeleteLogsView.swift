//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//

import SwiftUI

struct DeleteLogsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selecteduuids: Set<UUID>
    @Binding var isPresented: Bool
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

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
            let message = "Delete"
                + " \(selecteduuids.count)"
                + " log(s)?"
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
                                             scheduleConfigurations: rsyncUIdata.schedulesandlogs)
        deleteschedule.deletelogs(uuids: selecteduuids)
        reload = true
        selecteduuids.removeAll()
        isPresented = false
    }
}
