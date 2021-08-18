//
//  RsyncParametersView.swift
//  RsyncParametersView
//
//  Created by Thomas Evensen on 18/08/2021.
//

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @StateObject var parameters = ObserveableParametersRsync()
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var presentrsynccommandoview = false

    @State private var searchText: String = ""
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                EditRsyncParameter(450, $parameters.parameter8.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(450, $parameters.parameter9.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(450, $parameters.parameter10.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(450, $parameters.parameter11.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(450, $parameters.parameter12.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(450, $parameters.parameter13.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(450, $parameters.parameter14.onChange {
                    parameters.inputchangedbyuser = true
                })
            }

            ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                parameters.configuration = selectedconfig
            },
            reload: $reload)
        }

        Spacer()

        HStack {
            Button("Linux") {
                parameters.inputchangedbyuser = true
                parameters.suffixlinux = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("FreeBSD") {
                parameters.inputchangedbyuser = true
                parameters.suffixfreebsd = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Backup") {
                parameters.inputchangedbyuser = true
                parameters.backup = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()

            Button("Rsync") { presenteview() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentrsynccommandoview) {
                    RsyncCommandView(selectedconfig: $parameters.configuration, isPresented: $presentrsynccommandoview)
                }

            Button("Save") { saversyncparameters() }
                .buttonStyle(PrimaryButtonStyle())

                .buttonStyle(PrimaryButtonStyle())
        }
        .onAppear(perform: {
            parameters.configuration = selectedconfig
        })
    }
}

extension RsyncParametersView {
    func presenteview() {
        presentrsynccommandoview = true
    }

    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.rsyncdata?.profile,
                                     configurations: rsyncUIdata.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.inputchangedbyuser = false
        selectedconfig = nil
        reload = true
    }
}
