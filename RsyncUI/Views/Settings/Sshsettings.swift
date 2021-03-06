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

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()
                // Column 1
                VStack(alignment: .leading) {
                    ToggleView(NSLocalizedString("Local ssh keys found", comment: "ssh"), $usersettings.localsshkeys)

                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }

                    Section(header: headeruniqueue) {
                        uniqueuserversandloginslist
                    }
                }.padding()

                // Column 2
                VStack(alignment: .leading) {
                    Section(header: headersshkey) {
                        // Create ssh keys
                        Button(NSLocalizedString("Create keys", comment: "usersetting")) { createkeys() }
                            .buttonStyle(PrimaryButtonStyle())
                    }

                    Section(header: headercopykeys) {
                        Sshcopykey(selectedlogin: $selectedlogin)
                            .padding(1)

                        Sshverifykey(selectedlogin: $selectedlogin)
                            .padding(1)
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

    // Ssh Unique
    var headercopykeys: some View {
        Text(NSLocalizedString("Copy and verify ssh-keys", comment: "ssh settings"))
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

    // Header create key
    var headersshkey: some View {
        Text(NSLocalizedString("Create ssh key", comment: "settings"))
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

struct Sshcopykey: View {
    @Binding var selectedlogin: UniqueserversandLogins?

    var body: some View {
        VStack(alignment: .leading) {
            Button(NSLocalizedString("Copy", comment: "Copy button")) { copytopasteboard() }
                .buttonStyle(PrimaryButtonStyle())

            if copystring.isEmpty {
                Text(NSLocalizedString("Select a Unique usernames and servers", comment: ""))
                    .padding(10)
                    .border(Color.gray)
            } else {
                Text(copystring)
                    .padding(10)
                    .border(Color.gray)
            }
        }
    }

    var copystring: String {
        if let login = selectedlogin {
            return Ssh().copylocalpubrsakeyfile(remote: login)
        } else {
            return ""
        }
    }

    func copytopasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(copystring, forType: .string)
    }
}

struct Sshverifykey: View {
    @Binding var selectedlogin: UniqueserversandLogins?

    var body: some View {
        VStack(alignment: .leading) {
            Button(NSLocalizedString("Copy", comment: "Verify button")) { copytopasteboard() }
                .buttonStyle(PrimaryButtonStyle())

            if verifystring.isEmpty {
                Text(NSLocalizedString("Select a Unique usernames and servers", comment: ""))
                    .padding(10)
                    .border(Color.gray)
            } else {
                Text(verifystring)
                    .padding(10)
                    .border(Color.gray)
            }
        }
    }

    var verifystring: String {
        if let login = selectedlogin {
            return Ssh().verifyremotekey(remote: login)
        } else {
            return ""
        }
    }

    func copytopasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(verifystring, forType: .string)
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
}

// TODO:
/*
 Fixed - 1. Fix Save, drop some updates in Combine
 2. Dont show rsync path if default either /usr/bin or /usr/local/bin - make them as placeholders
 3. Verify create ssh keys
 */
