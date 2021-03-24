//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//
// swiftlint:disable line_length cyclomatic_complexity

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var reload: Bool
    @StateObject private var parameters = ObserveableParametersRsync()
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()
    // Show updated
    @State private var updated = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $parameters.configuration.onChange { rsyncOSXData.update() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)

            if updated == true { notifyupdated }
        }

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

            saveparameters
        }
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

extension RsyncParametersView {
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
            if parameters.parameter3 == nil { config.parameter3 = "" }
            if parameters.parameter4 == nil { config.parameter4 = "" }
            if parameters.parameter5 == nil { config.parameter5 = "" }

            let updateconfiguration =
                UpdateConfigurations(profile: rsyncOSXData.rsyncdata?.profile,
                                     configurations: rsyncOSXData.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(config)
            reload = true
            updated = true
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                updated = false
            }
        }
        parameters.isDirty = false
        parameters.inputchangedbyuser = false
    }
}
