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
    // Settings are changed
    @State private var showthumbsup: Bool = false
    @State private var settingsischanged: Bool = false
    // Startup
    @State private var isstarting: Bool = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    ToggleViewDefault(text: NSLocalizedString("Local ssh-key is present", comment: ""),
                                      binding: $localsshkeys)
                        .disabled(true)
                }
            } header: {
                Text("ssh-keys")
            }

            Section {
                setsshpath

                setsshport

            } header: {
                Text("ssh-keypath and ssh-port")
            }

            Section {
                if settingsischanged { thumbsupgreen }
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
        .onChange(of: settingsischanged) {
            guard settingsischanged == true else { return }
            _ = WriteUserConfigurationJSON(UserConfiguration())
            Logger.process.info("Usersettings is SAVED")
        }
        .onAppear {
            isstarting = true
            Logger.process.info("SSH seetingsview isstarting = TRUE")
            Task {
                try await Task.sleep(seconds: 3)
                isstarting = false
                Logger.process.info("SSH seetingsview isstarting = FALSE")
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup.fill")
            .foregroundColor(Color(.green))
            .imageScale(.large)
            .onAppear {
                Task {
                    try await Task.sleep(seconds: 2)
                    showthumbsup = false
                    settingsischanged = false
                }
            }
    }

    var setsshpath: some View {
        EditValue(400, NSLocalizedString("Global ssh-keypath and identityfile", comment: ""), $sshsettings.sshkeypathandidentityfile)
            .onAppear(perform: {
                if let sshkeypath = SharedReference.shared.sshkeypathandidentityfile {
                    sshsettings.sshkeypathandidentityfile = sshkeypath
                }
            })
            .onChange(of: sshsettings.sshkeypathandidentityfile) {
                if isstarting == false {
                    Task {
                        try await Task.sleep(seconds: 2)
                        sshsettings.sshkeypath(sshsettings.sshkeypathandidentityfile)
                        settingsischanged = true
                    }
                }
            }
    }

    var setsshport: some View {
        EditValue(400, NSLocalizedString("Global ssh-port", comment: ""),
                  $sshsettings.sshportnumber)
            .onAppear(perform: {
                if let sshport = SharedReference.shared.sshport {
                    sshsettings.sshportnumber = String(sshport)
                }
            })
            .onChange(of: sshsettings.sshportnumber) {
                if isstarting == false {
                    Task {
                        try await Task.sleep(seconds: 2)
                        sshsettings.sshport(sshsettings.sshportnumber)
                        settingsischanged = true
                    }
                }
            }
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
