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
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }

                    Section(header: headerremove) {
                        VStack(alignment: .leading) {
                            ToggleViewDefault("-e ssh", $parameters.removessh)
                            ToggleViewDefault("--compress", $parameters.removecompress)
                            ToggleViewDefault("--delete", $parameters.removedelete)
                        }
                    }

                    Section(header: headerdaemon) {
                        ToggleViewDefault("daemon", $parameters.daemon)
                    }

                    Spacer()
                }

                VStack {
                    ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                        parameters.setvalues(selectedconfig)
                    },
                    reload: $reload)

                    HStack {
                        RsyncCommandView(selectedconfig: selectedconfig)

                        Spacer()
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Save") { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = "Default profile"
            }
        })
    }

    // Header remove
    var headerremove: some View {
        Text("Remove default rsync parameters")
    }

    // Ssh header
    var headerssh: some View {
        Text("Set ssh keypath and identityfile")
    }

    // Daemon header
    var headerdaemon: some View {
        Text("Enable rsync daemon")
    }

    var setsshpath: some View {
        EditValue(250, "Local ssh keypath and identityfile",
                  $parameters.sshkeypathandidentityfile)
            .onAppear(perform: {
                if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                    parameters.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, "Local ssh port", $parameters.sshport)
            .onAppear(perform: {
                if let sshport = parameters.configuration?.sshport {
                    parameters.sshport = String(sshport)
                }
            })
    }
}

extension RsyncDefaultParametersView {
    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.rsyncdata?.profile,
                                     configurations: rsyncUIdata.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
    }
}
