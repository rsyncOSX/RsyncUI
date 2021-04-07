//
//  DeleteSchedulesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/03/2021.
//

import SwiftUI

struct DeleteSchedulesView: View {
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
                Button(NSLocalizedString("Delete", comment: "Dismiss button")) { delete() }
                    .buttonStyle(AbortButtonStyle())

                Button(NSLocalizedString("Cancel", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Delete", comment: "Alert delete")
                + " \(selecteduuids.count)"
                + NSLocalizedString(" schedules(s)?", comment: "Alert delete")
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
                                             scheduleConfigurations: rsyncUIData.schedulesandlogs)
        deleteschedule.deleteschedules(uuids: selecteduuids)
        reload = true
        selecteduuids.removeAll()
        isPresented = false
    }
}
