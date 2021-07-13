//
//  DeleteSchedulesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/03/2021.
//

import SwiftUI

struct ChangeSchedulesView: View {
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
                Button("Cancel") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Stop") { stop() }
                    .buttonStyle(AbortButtonStyle())

                Button("Delete") { delete() }
                    .buttonStyle(AbortButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = "Stop or delete"
                + " \(selecteduuids.count)"
                + " schedules(s)?"
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        // selecteduuids.removeAll()
        isPresented = false
    }

    func delete() {
        let deleteschedule = UpdateSchedules(profile: selectedprofile,
                                             scheduleConfigurations: rsyncUIdata.schedulesandlogs)
        deleteschedule.deleteschedules(uuids: selecteduuids)
        reload = true
        // selecteduuids.removeAll()
        isPresented = false
    }

    func stop() {
        let stopschedule = UpdateSchedules(profile: selectedprofile,
                                           scheduleConfigurations: rsyncUIdata.schedulesandlogs)
        stopschedule.stopschedule(uuids: selecteduuids)
        reload = true
        // selecteduuids.removeAll()
        isPresented = false
    }
}
