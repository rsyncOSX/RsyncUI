//
//  RsyncParametersView.swift
//  RsyncParametersView
//
//  Created by Thomas Evensen on 18/08/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @StateObject var parameters = ObserveableParametersRsync()
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @State private var selectedconfig: Configuration?

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    EditRsyncParameter(450, $parameters.parameter8)
                    EditRsyncParameter(450, $parameters.parameter9)
                    EditRsyncParameter(450, $parameters.parameter10)
                    EditRsyncParameter(450, $parameters.parameter11)
                    EditRsyncParameter(450, $parameters.parameter12)
                    EditRsyncParameter(450, $parameters.parameter13)
                    EditRsyncParameter(450, $parameters.parameter14)

                    Spacer()
                }

                VStack {
                    ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                        parameters.setvalues(selectedconfig)
                    },
                    reload: $reload)
                }
            }

            HStack {
                RsyncCommandView(selectedconfig: selectedconfig)

                Spacer()
            }

            Spacer()

            HStack {
                Button("Linux") {
                    parameters.suffixlinux = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("FreeBSD") {
                    parameters.suffixfreebsd = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Backup") {
                    parameters.backup = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer()

                Button("Save") { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        /*
         .onAppear(perform: {
             if selectedprofile == nil {
                 selectedprofile = SharedReference.shared.defaultprofile
             }
         })
          */
    }
}

extension RsyncParametersView {
    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.configurationsfromstore?.profile,
                                     configurations: rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
    }
}
