//
//  JSONView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//

import SwiftUI

struct JSONView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @StateObject var usersettings = ObserveableReference()
    @State private var showingAlertconfig: Bool = false

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()
                // Column 1
                // Column 4
                VStack(alignment: .leading) {
                    Section(header: headerJSON) {
                        // Verify JSON or Plist
                        Button(NSLocalizedString("Verify", comment: "usersetting")) { verifyconverted(profile: rsyncOSXData.profile) }
                            .buttonStyle(PrimaryButtonStyle())

                        // Convert JSON or Plist
                        Button(NSLocalizedString("Convert", comment: "usersetting")) { showingAlertconfig = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .alert(isPresented: $showingAlertconfig) {
                                convertconfig
                            }
                    }

                    Section(header: headerbackupconfig) {
                        // Backup configuration files
                        Button(NSLocalizedString("Backup", comment: "usersetting")) { backupuserconfigs() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                }.padding()

                // For center
                Spacer()
            }
        }
        .lineSpacing(2)
        .padding()
    }

    // Header JSON
    var headerJSON: some View {
        Text(NSLocalizedString("JSON or PLIST", comment: "settings"))
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
                convertconfigurations(profile: rsyncOSXData.profile)
            }),
            secondaryButton: Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "")), action: {
                usersettings.isDirty = false
            })
        )
    }
}

extension JSONView {
    func backupuserconfigs() {
        _ = Backupconfigfiles()
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
