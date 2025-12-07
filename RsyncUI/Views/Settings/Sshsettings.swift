//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//

import OSLog
import SwiftUI

struct Sshsettings: View {
    @State private var sshsettings = ObservableSSH()
    @State private var localsshkeys: Bool = SshKeys().validatepublickeypresent()
    // Show keys are created
    @State private var showsshkeyiscreated: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Global ssh-keys")
                .font(.title3)
                .fontWeight(.bold)) {
                    VStack(alignment: .leading) {
                        ToggleViewDefault(text: NSLocalizedString("Public ssh-key is present", comment: ""),
                                          binding: $localsshkeys)
                            .disabled(true)
                    }
                }

            Section(header: Text("Global ssh-keypath and ssh-port")
                .font(.title3)
                .fontWeight(.bold)) {
                    EditValueErrorScheme(400, NSLocalizedString("Global ssh-keypath and identityfile", comment: ""), $sshsettings.sshkeypathandidentityfile,
                                         sshsettings.sshkeypath(sshsettings.sshkeypathandidentityfile))

                    EditValueErrorScheme(400, NSLocalizedString("Global ssh-port", comment: ""),
                                         $sshsettings.sshportnumber, sshsettings.setsshport(sshsettings.sshportnumber))
                }

            Section(header: Text("Save userconfiguration")
                .font(.title3)
                .fontWeight(.bold)) {
                    ConditionalGlassButton(
                        systemImage: "square.and.arrow.down",
                        text: "Save",
                        helpText: "Save userconfiguration"
                    ) {
                        _ = WriteUserConfigurationJSON(UserConfiguration())
                    }
                }

            if localsshkeys == false {
                Section(header: Text("SSH keys")
                    .font(.title3)
                    .fontWeight(.bold)) {
                        HStack {
                            Button {
                                createKeys()
                            } label: {
                                Image(systemName: "key")
                            }
                            .help("Create keys")
                            .buttonStyle(.borderedProminent)
                        }
                    }
            }

            if showsshkeyiscreated { DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("ssh-key is created, see logfile.", comment: "")) }
        }
        .formStyle(.grouped)
    }
}

extension Sshsettings {
    func createKeys() {
        if SshKeys().createPublicPrivateRSAKeyPair() {
            Task {
                try await Task.sleep(seconds: 1)
                localsshkeys = SshKeys().validatepublickeypresent()
                showsshkeyiscreated = true
            }
        }
    }
}
