//
//  RsyncDefaultParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//

import SwiftUI

struct RsyncDefaultParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @StateObject var parameters = ObserveableParametersDefault()
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var presentrsynccommandoview = false

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Section(header: headerremove) {
                        VStack(alignment: .leading) {
                            ToggleViewDefault("-e ssh", $parameters.removessh.onChange {
                                parameters.inputchangedbyuser = true
                            })
                            ToggleViewDefault("--compress", $parameters.removecompress.onChange {
                                parameters.inputchangedbyuser = true
                            })
                            ToggleViewDefault("--delete", $parameters.removedelete.onChange {
                                parameters.inputchangedbyuser = true
                            })
                        }
                    }

                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }
                }

                ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                    parameters.configuration = selectedconfig
                },
                reload: $reload)
            }

            Spacer()

            HStack {
                Spacer()

                Button("Rsync") { presenteview() }
                    .buttonStyle(PrimaryButtonStyle())
                    .sheet(isPresented: $presentrsynccommandoview) {
                        RsyncCommandView(selectedconfig: $parameters.configuration, isPresented: $presentrsynccommandoview)
                    }

                Button("Save") { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    // Header remove
    var headerremove: some View {
        Text("Remove default rsync parameters")
    }

    // Ssh header
    var headerssh: some View {
        Text("Set ssh keypath and identityfile")
    }

    var setsshpath: some View {
        EditValue(250, "Local ssh keypath and identityfile",
                  $parameters.sshkeypathandidentityfile.onChange {
                      parameters.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                    parameters.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, "Local ssh port", $parameters.sshport.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshport = parameters.configuration?.sshport {
                    parameters.sshport = String(sshport)
                }
            })
    }
}

extension RsyncDefaultParametersView {
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
