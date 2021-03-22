//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//
// swiftlint:disable line_length

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

        HStack {
            VStack(alignment: .leading) {
                EditRsyncParameter(550, $parameters.parameter8.wrappedValue, $parameters.parameter8.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter9.wrappedValue, $parameters.parameter9.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter10.wrappedValue, $parameters.parameter10.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter11.wrappedValue, $parameters.parameter11.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter12.wrappedValue, $parameters.parameter12.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter13.wrappedValue, $parameters.parameter13.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter14.wrappedValue, $parameters.parameter14.onChange {
                    parameters.inputchangedbyuser = true
                })
            }

            VStack {
                HStack {
                    ToggleView(NSLocalizedString("-e shh", comment: "settings"), $parameters.removessh.onChange {
                        parameters.inputchangedbyuser = true
                    })
                    ToggleView(NSLocalizedString("--compress", comment: "settings"), $parameters.removecompress.onChange {
                        parameters.inputchangedbyuser = true
                    })
                    ToggleView(NSLocalizedString("--delete", comment: "settings"), $parameters.removedelete.onChange {
                        parameters.inputchangedbyuser = true
                    })
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
            Button(NSLocalizedString("Linux", comment: "SidebarRsyncParameter")) {
                parameters.suffixlinux = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("FreeBSD", comment: "SidebarRsyncParameter")) {
                parameters.suffixfreebsd = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Daemon", comment: "SidebarRsyncParameter")) {
                parameters.daemon = true
                parameters.inputchangedbyuser = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Backup", comment: "SidebarRsyncParameter")) {
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

    // Ssh header
    var headerssh: some View {
        Text(NSLocalizedString("Set ssh keypath and identityfile", comment: "ssh settings"))
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Local ssh keypath and identityfile", comment: "settings"), $parameters.sshkeypathandidentityfile.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                    parameters.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Local ssh port", comment: "settings"), $parameters.sshport.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshport = parameters.configuration?.sshport {
                    parameters.sshport = String(sshport)
                }
            })
    }
}

extension RsyncParametersView {
    func saversyncparameters() {
        parameters.isDirty = false
        parameters.inputchangedbyuser = false
    }
}
