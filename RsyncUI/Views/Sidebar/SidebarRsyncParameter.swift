//
//  SidebarRsyncParameter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import SwiftUI

struct SidebarRsyncParameter: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @StateObject private var parameters = ObserveableParametersRsync()

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        VStack {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)

            VStack {
                EditRsyncParameter(250, $parameters.parameter8.wrappedValue, $parameters.parameter8)
                EditRsyncParameter(250, $parameters.parameter9.wrappedValue, $parameters.parameter9)
                EditRsyncParameter(250, $parameters.parameter10.wrappedValue, $parameters.parameter10)
                EditRsyncParameter(250, $parameters.parameter11.wrappedValue, $parameters.parameter11)
                EditRsyncParameter(250, $parameters.parameter12.wrappedValue, $parameters.parameter12)
                EditRsyncParameter(250, $parameters.parameter13.wrappedValue, $parameters.parameter13)
                EditRsyncParameter(250, $parameters.parameter14.wrappedValue, $parameters.parameter14)
            }

            Spacer()

            HStack {
                Spacer()
                // Add or Update button

                Button(NSLocalizedString("Button 1", comment: "Select button")) {}
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Button 2", comment: "Profiles")) {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}
