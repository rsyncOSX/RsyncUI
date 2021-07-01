//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Sshsettings: View {
    @StateObject var usersettings = ObservableSSH()

    @State private var selectedlogin: UniqueserversandLogins?
    @State private var showingAlert: Bool = false
    @State private var showsshverifysheet: Bool = false

    var uniqueserversandlogins: [UniqueserversandLogins]

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()
                // Column 1
                VStack(alignment: .leading) {
                    ToggleView(NSLocalizedString("Local ssh keys found", comment: ""), $usersettings.localsshkeys)

                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }

                }.padding()

                // Column 2
                VStack(alignment: .leading) {
                    Section(header: headeruniqueue) {
                        uniqueuserversandloginslist
                    }
                }.padding()

                // For center
                Spacer()
            }
            // Save button right down corner
            Spacer()

            HStack {
                Spacer()

                Button("Create") { createkeys() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Verify") { verifyssh() }
                    .buttonStyle(PrimaryButtonStyle())

                usersetting
            }
        }
        .lineSpacing(2)
        .padding()
        .sheet(isPresented: $showsshverifysheet) {
            VerifySshView(selectedlogin: $selectedlogin,
                          isPresented: $showsshverifysheet)
        }
    }

    // Save usersetting is changed
    var usersetting: some View {
        HStack {
            if usersettings.isDirty {
                Button("Save") { saveusersettings() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            } else {
                Button("Save") {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!usersettings.isDirty)
    }

    // Ssh header
    var headerssh: some View {
        Text("Set ssh keypath and identityfile")
    }

    // Ssh Unique
    var headeruniqueue: some View {
        Text("Unique usernames and servers")
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Global ssh keypath and identityfile", comment: ""), $usersettings.sshkeypathandidentityfile.onChange {
            usersettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshkeypath = SharedReference.shared.sshkeypathandidentityfile {
                    usersettings.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Global ssh port", comment: ""), $usersettings.sshport.onChange {
            usersettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshport = SharedReference.shared.sshport {
                    usersettings.sshport = String(sshport)
                }
            })
    }

    var uniqueuserversandloginslist: some View {
        List(selection: $selectedlogin) {
            ForEach(uniqueserversandlogins) { record in
                ServerRow(record: record)
                    .tag(record)
            }
        }
        .frame(width: 250, height: 100)
        .border(Color.gray)
    }

    // Header user setting
    var headerusersetting: some View {
        Text("Save settings")
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
        usersettings.isDirty = false
        usersettings.inputchangedbyuser = false
        _ = WriteUserConfigurationPLIST()
        // wait for a half second and then force a new check if keys are created and exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            usersettings.localsshkeys = SshKeys().validatepublickeypresent()
        }
    }

    func createkeys() {
        let create = SshKeys().createPublicPrivateRSAKeyPair()
        if create == true {
            // wait for a half second and then force a new check if keys are created and exists
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                usersettings.localsshkeys = SshKeys().validatepublickeypresent()
            }
        }
    }

    func verifyssh() {
        showsshverifysheet = true
    }
}
