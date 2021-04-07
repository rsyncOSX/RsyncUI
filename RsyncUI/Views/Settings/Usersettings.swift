//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Usersettings: View {
    @EnvironmentObject var rsyncOSXData: RsyncUIdata
    @EnvironmentObject var rsyncversionObject: RsyncOSXViewGetRsyncversion
    @StateObject var usersettings = ObserveableReference()

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()

                // Column 1
                VStack(alignment: .leading) {
                    Section(header: headerrsync) {
                        ToggleView(NSLocalizedString("Rsync ver 3.x", comment: "settings"), $usersettings.rsyncversion3.onChange {
                            usersettings.inputchangedbyuser = true
                            rsyncversionObject.update(usersettings.rsyncversion3)
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
                                ToggleView(NSLocalizedString("None", comment: "settings"), $usersettings.nologging.onChange {
                                    usersettings.inputchangedbyuser = true
                                    if usersettings.nologging == true {
                                        usersettings.minimumlogging = false
                                        usersettings.fulllogging = false
                                    } else {
                                        usersettings.minimumlogging = true
                                        usersettings.fulllogging = false
                                    }
                                })

                                ToggleView(NSLocalizedString("Min", comment: "settings"), $usersettings.minimumlogging.onChange {
                                    usersettings.inputchangedbyuser = true
                                    if usersettings.minimumlogging == true {
                                        usersettings.nologging = false
                                        usersettings.fulllogging = false
                                    }
                                })

                                ToggleView(NSLocalizedString("Full", comment: "settings"), $usersettings.fulllogging.onChange {
                                    usersettings.inputchangedbyuser = true
                                    if usersettings.fulllogging == true {
                                        usersettings.nologging = false
                                        usersettings.minimumlogging = false
                                    }
                                })
                            }
                        }

                        VStack(alignment: .leading) {
                            Section(header: headerdetailedlogging) {
                                ToggleView(NSLocalizedString("Detailed", comment: "settings"), $usersettings.detailedlogging.onChange {
                                    usersettings.inputchangedbyuser = true
                                })
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
                        ToggleView(NSLocalizedString("Monitor network", comment: "settings"), $usersettings.monitornetworkconnection.onChange {
                            usersettings.inputchangedbyuser = true
                        })

                        ToggleView(NSLocalizedString("Check data", comment: "settings"), $usersettings.checkinput.onChange {
                            usersettings.inputchangedbyuser = true
                        })
                    }
                }
                .padding()

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
        Text(NSLocalizedString("Level log", comment: "settings"))
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
}

extension Usersettings {
    func saveusersettings() {
        usersettings.isDirty = false
        usersettings.inputchangedbyuser = false
        PersistentStorageUserconfiguration().saveuserconfiguration()
    }
}
