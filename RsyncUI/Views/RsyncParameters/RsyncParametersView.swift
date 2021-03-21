//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var reload: Bool
    @StateObject private var parameters = ObserveableParametersRsync()
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        ConfigurationsList(selectedconfig: $parameters.configuration.onChange { rsyncOSXData.update() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        VStack(alignment: .leading) {
            EditRsyncParameter(600, $parameters.parameter8.wrappedValue, $parameters.parameter8.onChange {
                parameters.inputchangedbyuser = true
            })
            EditRsyncParameter(600, $parameters.parameter9.wrappedValue, $parameters.parameter9.onChange {
                parameters.inputchangedbyuser = true
            })
            EditRsyncParameter(600, $parameters.parameter10.wrappedValue, $parameters.parameter10.onChange {
                parameters.inputchangedbyuser = true
            })
            EditRsyncParameter(600, $parameters.parameter11.wrappedValue, $parameters.parameter11.onChange {
                parameters.inputchangedbyuser = true
            })
            EditRsyncParameter(600, $parameters.parameter12.wrappedValue, $parameters.parameter12.onChange {
                parameters.inputchangedbyuser = true
            })
            EditRsyncParameter(600, $parameters.parameter13.wrappedValue, $parameters.parameter13.onChange {
                parameters.inputchangedbyuser = true
            })
            EditRsyncParameter(600, $parameters.parameter14.wrappedValue, $parameters.parameter14.onChange {
                parameters.inputchangedbyuser = true
            })
        }

        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Button 1", comment: "SidebarRsyncParameter")) {}
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Button 2", comment: "SidebarRsyncParameter")) {}
                .buttonStyle(PrimaryButtonStyle())
            
            saveparameters
        }
    }

    // Save usersetting is changed
    var saveparameters: some View {
        HStack {
            if parameters.isDirty {
                Button(NSLocalizedString("Save", comment: "usersetting")) { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            } else {
                Button(NSLocalizedString("Save", comment: "usersetting")) {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!parameters.isDirty)
    }
}

extension RsyncParametersView {
    func saversyncparameters() {}
}
