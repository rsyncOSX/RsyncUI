//
//  DetailedRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct DetailedRsyncParametersView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var reload: Bool
    @Binding var updated: Bool
    @Binding var showdetails: Bool
    @Binding var selectedconfig: Configuration?

    @StateObject var parameters = ObserveableParametersRsync()

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()
    // Show updated
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
                    HStack {
                        ToggleView(NSLocalizedString("-e shh", comment: "RsyncParametersView"), $parameters.removessh.onChange {
                            parameters.inputchangedbyuser = true
                        })
                        ToggleView(NSLocalizedString("--compress", comment: "RsyncParametersView"), $parameters.removecompress.onChange {
                            parameters.inputchangedbyuser = true
                        })
                        ToggleView(NSLocalizedString("--delete", comment: "RsyncParametersView"), $parameters.removedelete.onChange {
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
            Button(NSLocalizedString("Linux", comment: "RsyncParametersView")) {
                parameters.suffixlinux = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("FreeBSD", comment: "RsyncParametersView")) {
                parameters.suffixfreebsd = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Daemon", comment: "RsyncParametersView")) {
                parameters.daemon = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Backup", comment: "RsyncParametersView")) {
                parameters.backup = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()

            Button(NSLocalizedString("Rsync", comment: "RsyncParametersView")) { presenteview() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentrsynccommandoview) {
                    RsyncCommandView(selectedconfig: $parameters.configuration, isPresented: $presentrsynccommandoview)
                }

            saveparameters

            Button(NSLocalizedString("Return", comment: "RsyncParametersView")) {
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
                Button(NSLocalizedString("Save", comment: "RsyncParametersView")) { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            } else {
                Button(NSLocalizedString("Save", comment: "RsyncParametersView")) {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!parameters.isDirty)
    }

    // Header remove
    var headerremove: some View {
        Text(NSLocalizedString("Remove default rsync parameters", comment: "RsyncParametersView"))
    }

    // Ssh header
    var headerssh: some View {
        Text(NSLocalizedString("Set ssh keypath and identityfile", comment: "RsyncParametersView"))
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Local ssh keypath and identityfile", comment: "RsyncParametersView"), $parameters.sshkeypathandidentityfile.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                    parameters.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Local ssh port", comment: "RsyncParametersView"), $parameters.sshport.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshport = parameters.configuration?.sshport {
                    parameters.sshport = String(sshport)
                }
            })
    }

    var notifyupdated: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Updated", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }
}

extension DetailedRsyncParametersView {
    func presenteview() {
        presentrsynccommandoview = true
    }

    func saversyncparameters() {
        if var config = parameters.configuration {
            if parameters.parameter8.isEmpty { config.parameter8 = nil } else { config.parameter8 = parameters.parameter8 }
            if parameters.parameter9.isEmpty { config.parameter9 = nil } else { config.parameter9 = parameters.parameter9 }
            if parameters.parameter10.isEmpty { config.parameter10 = nil } else { config.parameter10 = parameters.parameter10 }
            if parameters.parameter11.isEmpty { config.parameter11 = nil } else { config.parameter11 = parameters.parameter11 }
            if parameters.parameter12.isEmpty { config.parameter12 = nil } else { config.parameter12 = parameters.parameter12 }
            if parameters.parameter13.isEmpty { config.parameter13 = nil } else { config.parameter13 = parameters.parameter13 }
            if parameters.parameter14.isEmpty { config.parameter14 = nil } else { config.parameter14 = parameters.parameter14 }
            if parameters.sshport.isEmpty {
                config.sshport = nil
            } else {
                config.sshport = Int(parameters.sshport)
            }
            if parameters.sshkeypathandidentityfile.isEmpty {
                config.sshkeypathandidentityfile = nil
            } else {
                config.sshkeypathandidentityfile = parameters.sshkeypathandidentityfile
            }
            if parameters.parameter3 == nil { config.parameter3 = "" } else { config.parameter3 = parameters.parameter3 ?? "" }
            if parameters.parameter4 == nil { config.parameter4 = "" } else { config.parameter4 = parameters.parameter4 ?? "" }
            if parameters.parameter5 == nil { config.parameter5 = "" } else { config.parameter5 = parameters.parameter5 ?? "" }

            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIData.rsyncdata?.profile,
                                     configurations: rsyncUIData.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(config, true)
            reload = true
            updated = true
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                updated = false
                selectedconfig = nil
                showdetails = false
            }
        }
        parameters.isDirty = false
        parameters.inputchangedbyuser = false
    }
}
