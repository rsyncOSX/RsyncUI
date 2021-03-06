//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Usersettings: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var errorhandling: ErrorHandling
    @EnvironmentObject var rsyncversionObject: RsyncOSXViewGetRsyncversion
    @StateObject var usersettings = ObserveableReference()

    @State private var showingAlertjson: Bool = false
    @State private var showingAlertconfig: Bool = false

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()

                // Column 1
                VStack(alignment: .leading) {
                    Section(header: headerrsync) {
                        ToggleView(NSLocalizedString("Rsync ver 3.x", comment: "settings"), $usersettings.rsyncversion3.onChange {
                            rsyncversionObject.update()
                        })

                        // Only preset localpath for rsync if locapath is set. If default values either in /usr/bin or
                        // /usr/local/bin set as placeholder value to present path
                        if usersettings.localrsyncpath.isEmpty == true { setrsyncpathdefault } else { setrsyncpathlocalpath }
                    }

                    Section(header: headerpathforrestore) {
                        setpathforrestore
                    }
                }.padding()

                // Column 2
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Section(header: headerloggingtofile) {
                                ToggleView(NSLocalizedString("No log", comment: "settings"), $usersettings.nologging)

                                ToggleView(NSLocalizedString("Min", comment: "settings"), $usersettings.minimumlogging)

                                ToggleView(NSLocalizedString("Full", comment: "settings"), $usersettings.fulllogging)
                            }
                        }

                        VStack(alignment: .leading) {
                            Section(header: headerdetailedlogging) {
                                ToggleView(NSLocalizedString("Detailed", comment: "settings"), $usersettings.detailedlogging)
                            }

                            Section(header: headermarkdays) {
                                setmarkdays
                            }
                        }
                    }
                }.padding()

                // Column 3
                VStack(alignment: .leading) {
                    Section(header: headerothersettings) {
                        ToggleView(NSLocalizedString("Monitor network", comment: "settings"), $usersettings.monitornetworkconnection)

                        ToggleView(NSLocalizedString("Check input", comment: "settings"), $usersettings.checkinput)

                        ToggleView(NSLocalizedString("Enable JSON", comment: "settings"), $usersettings.json.onChange {
                            showingAlertjson = true
                        })
                            .alert(isPresented: $showingAlertjson) {
                                enablejson
                            }
                    }
                }
                .padding()

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

    // Rsync
    var headerrsync: some View {
        Text(NSLocalizedString("Rsync version and path", comment: "settings"))
    }

    var setrsyncpathlocalpath: some View {
        EditValue(250, nil, $usersettings.localrsyncpath)
            .onAppear(perform: {
                usersettings.localrsyncpath = SetandValidatepathforrsync().getpathforrsync()
            })
    }

    var setrsyncpathdefault: some View {
        EditValue(250, SetandValidatepathforrsync().getpathforrsync(), $usersettings.localrsyncpath)
    }

    // Restore path
    var headerpathforrestore: some View {
        Text(NSLocalizedString("Path for restore", comment: "settings"))
    }

    var setpathforrestore: some View {
        EditValue(250, NSLocalizedString("Path for restore", comment: "settings"), $usersettings.temporarypathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    usersettings.temporarypathforrestore = pathforrestore
                }
            })
    }

    // Logging
    var headerloggingtofile: some View {
        Text(NSLocalizedString("Log to file", comment: "settings"))
    }

    // Detail of logging
    var headerdetailedlogging: some View {
        Text(NSLocalizedString("Loglevel", comment: "settings"))
    }

    // Header other settings
    var headerothersettings: some View {
        Text(NSLocalizedString("Other settings", comment: "settings"))
    }

    // Header user setting
    var headerusersetting: some View {
        Text(NSLocalizedString("Save settings", comment: "settings"))
    }

    // Header backup
    var headerbackupconfig: some View {
        Text(NSLocalizedString("Configurations", comment: "settings"))
    }

    // Header backup
    var headermarkdays: some View {
        Text(NSLocalizedString("Mark days", comment: "settings"))
    }

    var setmarkdays: some View {
        TextField(String(SharedReference.shared.marknumberofdayssince),
                  text: $usersettings.marknumberofdayssince)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 70)
            .lineLimit(1)
    }

    var enablejson: Alert {
        Alert(
            title: Text(NSLocalizedString("Enable JSON or PLIST?", comment: "")),
            message: Text(NSLocalizedString("Cancel or OK", comment: "")),
            primaryButton: Alert.Button.default(Text(NSLocalizedString("OK", comment: "")), action: {
                rsyncversionObject.update()
            }),
            secondaryButton: Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "")), action: {
                let resetvalue = $usersettings.json.wrappedValue
                usersettings.json = !resetvalue
                usersettings.isDirty = false
            })
        )
    }

    // Header JSON
    var headerJSON: some View {
        Text(NSLocalizedString("JSON or PLIST", comment: "settings"))
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

extension Usersettings {
    func saveusersettings() {
        usersettings.isDirty = false
        PersistentStorageUserconfiguration().saveuserconfiguration()
    }

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
