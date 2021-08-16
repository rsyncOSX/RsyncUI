//
//  DetailedRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2021.
//

import SwiftUI

struct DetailedRsyncParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @StateObject var parameters = ObserveableParametersRsync()

    @Binding var reload: Bool
    @Binding var showdetails: Bool
    @Binding var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var presentrsynccommandoview = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                EditRsyncParameter(550, $parameters.parameter8.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter9.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter10.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter11.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter12.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter13.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter14.onChange {
                    parameters.inputchangedbyuser = true
                })
            }

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

                VStack(alignment: .leading) {
                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }
                }
            }
        }

        Spacer()

        HStack {
            Button("Linux") {
                parameters.suffixlinux = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("FreeBSD") {
                parameters.suffixfreebsd = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Daemon") {
                parameters.daemon = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Backup") {
                parameters.backup = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()

            Button("Rsync") { presenteview() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentrsynccommandoview) {
                    RsyncCommandView(selectedconfig: $parameters.configuration, isPresented: $presentrsynccommandoview)
                }

            saveparameters

            Button("Return") {
                selectedconfig = nil
                showdetails = false
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .onAppear(perform: {
            parameters.configuration = selectedconfig
        })
    }

    // Save usersetting is changed
    var saveparameters: some View {
        HStack {
            if parameters.isDirty {
                Button("Save") { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Save") {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!parameters.isDirty)
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

extension DetailedRsyncParametersView {
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
        parameters.isDirty = false
        parameters.inputchangedbyuser = false
    }
}
