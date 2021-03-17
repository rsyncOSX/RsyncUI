//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//

import SwiftUI

struct DeleteLogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
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
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Delete", comment: "Alert delete")
                + " \(selecteduuids.count)"
                + NSLocalizedString(" log(s)?", comment: "Alert delete")
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
                                             scheduleConfigurations: rsyncOSXData.schedulesandlogs)
        deleteschedule.deletelogs(uuids: selecteduuids)
        reload = true
        selecteduuids.removeAll()
        isPresented = false
    }
}
