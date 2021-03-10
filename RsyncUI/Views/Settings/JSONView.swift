//
//  JSONView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//

import SwiftUI

struct JSONView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var selectedprofile: String?

    @State private var showingAlertconfig: Bool = false
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

                    Section(header: headerbackupconfig) {
                        // Backup configuration files
                        Button(NSLocalizedString("Backup", comment: "usersetting")) { backupuserconfigs() }
                            .buttonStyle(PrimaryButtonStyle())
                    }

                    // Present when either added, updated or profile created
                    if converted == true { notifyconverted }
                    if backup == true { notifybackup }
                }
                .padding()

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
                convertconfigurations(profile: selectedprofile)
            }),
            secondaryButton: Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "")), action: {})
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
