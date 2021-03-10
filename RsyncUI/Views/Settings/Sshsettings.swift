//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Sshsettings: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var errorhandling: ErrorHandling
    @StateObject var usersettings = ObserveableReference()
    @Binding var selectedconfig: Configuration?
    @State private var selectedlogin: UniqueserversandLogins?

    @State private var showingAlert: Bool = false
    @State private var showsshverifysheet: Bool = false

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()
                // Column 1
                VStack(alignment: .leading) {
                    HStack {
                        ToggleView(NSLocalizedString("Local ssh keys found", comment: "ssh"), $usersettings.localsshkeys)

                        VStack {
                            Button(NSLocalizedString("Create", comment: "usersetting")) { createkeys() }
                                .buttonStyle(PrimaryButtonStyle())

                            Button(NSLocalizedString("Verify", comment: "usersetting")) { verifyssh() }
                                .buttonStyle(PrimaryButtonStyle())
                        }
                    }

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
                Button(NSLocalizedString("Save", comment: "usersetting")) { saveusersettings() }
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
        .disabled(!usersettings.isDirty)
    }

    // Ssh keypath
    var headerssh: some View {
        Text(NSLocalizedString("Set ssh keypath and identityfile", comment: "ssh settings"))
    }

    // Ssh Unique
    var headeruniqueue: some View {
        Text(NSLocalizedString("Unique usernames and servers", comment: "ssh settings"))
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Global ssh keypath and identityfile", comment: "settings"), $usersettings.sshkeypathandidentityfile)
            .onAppear(perform: {
                if let sshkeypath = SharedReference.shared.sshkeypathandidentityfile {
                    usersettings.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Global ssh port", comment: "settings"), $usersettings.sshport)
            .onAppear(perform: {
                if let sshport = SharedReference.shared.sshport {
                    usersettings.sshport = String(sshport)
                }
            })
    }

    var uniqueuserversandloginslist: some View {
        List(selection: $selectedlogin) {
            ForEach(serversandlogins) { record in
                ServerRow(record: record)
                    .tag(record)
            }
        }
        .frame(width: 250, height: 100)
        .border(Color.gray)
    }

    var serversandlogins: [UniqueserversandLogins] {
        if let servers = rsyncOSXData.rsyncdata?.configurationData.getuniqueueserversandlogins() {
            return servers
        }
        return []
    }

    // Header user setting
    var headerusersetting: some View {
        Text(NSLocalizedString("Save settings", comment: "settings"))
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
        PersistentStorageUserconfiguration().saveuserconfiguration()
    }

    func createkeys() {
        Ssh().createPublicPrivateRSAKeyPair()
    }

    func verifyssh() {
        showsshverifysheet = true
    }
}

// TODO:
/*
 Fixed - 1. Fix Save, drop some updates in Combine
 2. Dont show rsync path if default either /usr/bin or /usr/local/bin - make them as placeholders
 3. Verify create ssh keys
 */
