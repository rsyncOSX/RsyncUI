//
//  JSONView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct JSONView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var rsyncversionObject: RsyncOSXViewGetRsyncversion
    @StateObject var usersettings = ObserveableReferenceJSON()
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var showingAlertconfig: Bool = false
    @State private var showingAlertjson: Bool = false
    // Added and updated labels
    @State private var converted = false
    @State private var backup = false

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()
                // Column 1
                VStack(alignment: .leading) {
                    Section(header: headerJSON) {
                        // Verify JSON or Plist
                        Button(NSLocalizedString("Verify", comment: "usersetting")) { verifyconverted(profile: selectedprofile) }
                            .buttonStyle(PrimaryButtonStyle())

                        // Convert JSON or Plist
                        Button(NSLocalizedString("Convert", comment: "usersetting")) { showingAlertconfig = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .alert(isPresented: $showingAlertconfig) {
                                convertconfig
                            }
                    }
                }
                .padding()

                // Column 2
                VStack(alignment: .leading) {
                    Section(header: headerjsonsettings) {
                        ToggleView(NSLocalizedString("Enable JSON", comment: "settings"), $usersettings.json.onChange {
                            showingAlertjson = true
                            usersettings.inputchangedbyuser = true
                        })
                            .alert(isPresented: $showingAlertjson) {
                                enablejson
                            }
                    }
                }
                .padding()
                // For center

                // Column 3
                VStack(alignment: .leading) {
                    Section(header: headerbackupconfig) {
                        // Backup configuration files
                        Button(NSLocalizedString("Backup", comment: "usersetting")) { backupuserconfigs() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
                // For center
                Spacer()
            }
            // Present when either added, updated or profile created
            HStack {
                Spacer()

                if backup == true { notifybackup }
                if converted == true { notifyconverted }

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

    // Header JSON
    var headerJSON: some View {
        Text(NSLocalizedString("JSON or PLIST", comment: "settings"))
    }

    // Header other settings
    var headerjsonsettings: some View {
        Text(NSLocalizedString("Enable or disable JSON", comment: "settings"))
    }

    // Header backup
    var headerbackupconfig: some View {
        Text(NSLocalizedString("Configurations", comment: "settings"))
    }

    var convertconfig: Alert {
        Alert(
            title: Text(NSLocalizedString("Convert configurations?", comment: "")),
            message: Text(NSLocalizedString("Cancel or OK", comment: "")),
            primaryButton: Alert.Button.default(Text(NSLocalizedString("OK", comment: "")), action: {
                convertconfigurations(profile: selectedprofile)
            }),
            secondaryButton: Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "")), action: {})
        )
    }

    var enablejson: Alert {
        Alert(
            title: Text(NSLocalizedString("Enable JSON or PLIST?", comment: "")),
            message: Text(NSLocalizedString("Cancel or OK", comment: "")),
            primaryButton: Alert.Button.default(Text(NSLocalizedString("OK", comment: "")), action: {
                rsyncversionObject.reload()
            }),
            secondaryButton: Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "")), action: {
                let resetvalue = $usersettings.json.wrappedValue
                usersettings.inputchangedbyuser = false
                usersettings.json = !resetvalue
                usersettings.isDirty = false
            })
        )
    }

    var notifyconverted: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Converted", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var notifybackup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Saved", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    // Save usersetting is changed
    // Disabled if not dirty
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
}

extension JSONView {
    func backupuserconfigs() {
        _ = Backupconfigfiles()
        backup = true
        // Show updated for 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            backup = false
        }
    }

    func convertconfigurations(profile: String?) {
        var myprofile: String?

        if profile != nil {
            if profile == NSLocalizedString("Default profile", comment: "convert") {
                myprofile = nil
            } else {
                myprofile = profile
            }
        }
        PersistentStorage(profile: myprofile,
                          whattoreadorwrite: .configuration,
                          readonly: true,
                          configurations: rsyncOSXData.configurations,
                          schedules: rsyncOSXData.schedulesandlogs)
            .convert(profile: myprofile)
        converted = true
        // Show updated for 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            converted = false
        }
    }

    func verifyconverted(profile: String?) {
        var myprofile: String?

        if profile != nil {
            if profile == NSLocalizedString("Default profile", comment: "convert") {
                myprofile = nil
            } else {
                myprofile = profile
            }
        }
        _ = VerifyJSON(profile: myprofile)
    }
}

extension JSONView {
    func saveusersettings() {
        usersettings.isDirty = false
        usersettings.inputchangedbyuser = false
        PersistentStorageUserconfiguration().saveuserconfiguration()
        reload = true
    }
}
