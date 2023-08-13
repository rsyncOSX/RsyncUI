//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Sshsettings: View {
    @SwiftUI.Environment(AlertError.self) private var alerterror
    @State private var usersettings = ObservableSSH()

    @State private var selectedlogin: UniqueserversandLogins?
    @State private var backup = false
    @State private var localsshkeys: Bool = false // SshKeys().validatepublickeypresent()

    var uniqueserversandlogins: [UniqueserversandLogins]

    var body: some View {
        Form {
            Spacer()

            ZStack {
                HStack {
                    // For center
                    Spacer()
                    // Column 1
                    VStack(alignment: .leading) {
                        ToggleViewDefault(NSLocalizedString("Local ssh keys are present", comment: ""), $localsshkeys)

                        setsshpath

                        setsshport
                    }

                    // Column 2
                    VStack(alignment: .leading) {
                        // Section(header: headeruniqueue) {
                        uniqueuserversandloginslist
                        // }
                    }

                    // For center
                    Spacer()
                }

                if backup == true {
                    AlertToast(type: .complete(Color.green),
                               title: Optional(NSLocalizedString("Saved", comment: "")), subTitle: Optional(""))
                        .onAppear(perform: {
                            // Show updated for 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                backup = false
                            }
                        })
                }
            }
            // Save button right down corner
            Spacer()

            HStack {
                if selectedlogin != nil { strings }

                Spacer()

                Button("Create") { createkeys() }
                    .buttonStyle(ColorfulButtonStyle())

                Button("Save") { saveusersettings() }
                    .buttonStyle(ColorfulButtonStyle())
            }
        }
        .padding()
        .onAppear(perform: {
            localsshkeys = SshKeys().validatepublickeypresent()
        })
        .alert(isPresented: $usersettings.alerterror,
               content: { Alert(localizedError: usersettings.error)
               })
    }

    // Copy strings

    var strings: some View {
        VStack(alignment: .leading) {
            Text(verifystring)
            Text(copystring)
        }
        .textSelection(.enabled)
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Global ssh keypath and identityfile", comment: ""), $usersettings.sshkeypathandidentityfile)
            .onAppear(perform: {
                if let sshkeypath = SharedReference.shared.sshkeypathandidentityfile {
                    usersettings.sshkeypathandidentityfile = sshkeypath
                }
            })
            .onChange(of: usersettings.sshkeypathandidentityfile) {
                usersettings.sshkeypath(usersettings.sshkeypathandidentityfile)
            }
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Global ssh port", comment: ""),
                  $usersettings.sshportnumber)
            .onAppear(perform: {
                if let sshport = SharedReference.shared.sshport {
                    usersettings.sshportnumber = String(sshport)
                }
            })
            .onChange(of: usersettings.sshportnumber) {
                usersettings.sshport(usersettings.sshportnumber)
            }
    }

    var uniqueuserversandloginslist: some View {
        List(selection: $selectedlogin) {
            ForEach(uniqueserversandlogins) { record in
                ServerRow(record: record)
                    .tag(record)
            }
        }
        .frame(width: 250, height: 100)
    }

    var verifystring: String {
        if let login = selectedlogin {
            return SshKeys().verifyremotekey(remote: login)
        } else {
            return ""
        }
    }

    var copystring: String {
        if let login = selectedlogin {
            return SshKeys().copylocalpubrsakeyfile(remote: login)
        } else {
            return ""
        }
    }
}

struct ServerRow: View {
    var record: UniqueserversandLogins

    var body: some View {
        HStack {
            Text(record.offsiteUsername ?? "")
                .modifier(FixedTag(80, .leading))
            Text(record.offsiteServer ?? "")
                .modifier(FixedTag(80, .leading))
        }
    }
}

extension Sshsettings {
    func saveusersettings() {
        _ = WriteUserConfigurationJSON(UserConfiguration())
        backup = true
        // wait for a half second and then force a new check if keys are created and exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            localsshkeys = SshKeys().validatepublickeypresent()
        }
    }

    func createkeys() {
        let create = SshKeys().createPublicPrivateRSAKeyPair()
        if create == true {
            // wait for a half second and then force a new check if keys are created and exists
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                localsshkeys = SshKeys().validatepublickeypresent()
            }
        }
    }
}

struct UniqueserversandLogins: Hashable, Identifiable {
    var id = UUID()
    var offsiteUsername: String?
    var offsiteServer: String?

    init(_ username: String,
         _ servername: String)
    {
        offsiteServer = servername
        offsiteUsername = username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
    }
}
