//
//  DeleteConfigurationsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/02/2021.
//

import SwiftUI

struct DeleteConfigurationsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var selecteduuids: Set<UUID>
    @Binding var isPresented: Bool
    @Binding var reload: Bool

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
                + NSLocalizedString(" configuration(s)?", comment: "Alert delete")
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }

    func delete() {
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncOSXData.rsyncdata?.profile,
                                 configurations: rsyncOSXData.rsyncdata?.configurationData.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        isPresented = false
        reload = true
    }
}
