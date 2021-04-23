//
//  DeleteSchedulesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/03/2021.
//

import SwiftUI

struct ChangeSchedulesView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var selecteduuids: Set<UUID>
    @Binding var isPresented: Bool
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button(NSLocalizedString("Cancel", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Stop", comment: "Dismiss button")) { stop() }
                    .buttonStyle(AbortButtonStyle())

                Button(NSLocalizedString("Delete", comment: "Dismiss button")) { delete() }
                    .buttonStyle(AbortButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Stop or delete", comment: "Alert delete")
                + " \(selecteduuids.count)"
                + NSLocalizedString(" schedules(s)?", comment: "Alert delete")
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        selecteduuids.removeAll()
        isPresented = false
    }

    func delete() {
        let deleteschedule = UpdateSchedules(profile: selectedprofile,
                                             scheduleConfigurations: rsyncUIData.schedulesandlogs)
        deleteschedule.deleteschedules(uuids: selecteduuids)
        reload = true
        selecteduuids.removeAll()
        isPresented = false
    }

    func stop() {
        let stopschedule = UpdateSchedules(profile: selectedprofile,
                                           scheduleConfigurations: rsyncUIData.schedulesandlogs)
        stopschedule.stopschedule(uuids: selecteduuids)
        reload = true
        selecteduuids.removeAll()
        isPresented = false
    }
}
