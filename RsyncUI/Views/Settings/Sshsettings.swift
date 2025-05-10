//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import OSLog
import SwiftUI

struct Sshsettings: View {
    @State private var sshsettings = ObservableSSH()
    @State private var localsshkeys: Bool = SshKeys().validatepublickeypresent()
    // Show keys are created
    @State private var showsshkeyiscreated: Bool = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    ToggleViewDefault(text: NSLocalizedString("Local ssh-key is present", comment: ""),
                                      binding: $localsshkeys)
                        .disabled(true)
                }
            } header: {
                Text("Global ssh-keys")
            }

            Section {
                setsshpath

                setsshport

            } header: {
                Text("Global ssh-keypath and ssh-port")
            }

            Section {
                Button {
                    _ = WriteUserConfigurationJSON(UserConfiguration())
                    Logger.process.info("USER CONFIGURATION is SAVED")
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Save")
                .buttonStyle(ColorfulButtonStyle())
            } header: {
                Text("Save userconfiguration")
            }

            if localsshkeys == false {
                Section {
                    HStack {
                        Button {
                            createkeys()
                        } label: {
                            Image(systemName: "key")
                        }
                        .help("Create keys")
                        .buttonStyle(ColorfulButtonStyle())
                    }

                } header: {
                    Text("SSH keys")
                }
            }

            if showsshkeyiscreated { DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("ssh-key is created, see logfile.", comment: "")) }
        }
        .formStyle(.grouped)
    }

    var setsshpath: some View {
        EditValue(400, NSLocalizedString("Global ssh-keypath and identityfile", comment: ""), $sshsettings.sshkeypathandidentityfile)
            .foregroundColor(
                sshsettings.sshkeypath(sshsettings.sshkeypathandidentityfile) ? Color.white : Color.red)
    }

    var setsshport: some View {
        EditValue(400, NSLocalizedString("Global ssh-port", comment: ""),
                  $sshsettings.sshportnumber)
            .foregroundColor(
                sshsettings.setsshport(sshsettings.sshportnumber) ? Color.white : Color.red)
    }
}

extension Sshsettings {
    func createkeys() {
        if SshKeys().createPublicPrivateRSAKeyPair() {
            Task {
                try await Task.sleep(seconds: 1)
                localsshkeys = SshKeys().validatepublickeypresent()
                showsshkeyiscreated = true
            }
        }
    }
}

// swiftlint:enable line_length
