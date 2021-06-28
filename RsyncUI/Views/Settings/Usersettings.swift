//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Usersettings: View {
    @EnvironmentObject var rsyncversionObject: GetRsyncversion
    @StateObject var usersettings = ObserveableUsersetting()
    @State private var backup = false

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        Section(header: headerrsync) {
                            ToggleView("Rsync ver 3.x", $usersettings.rsyncversion3.onChange {
                                usersettings.inputchangedbyuser = true
                                rsyncversionObject.update(usersettings.rsyncversion3)
                            })

                            // Only preset localpath for rsync if locapath is set. If default values either in /usr/bin or
                            // /usr/local/bin set as placeholder value to present path
                            if usersettings.localrsyncpath.isEmpty == true {
                                setrsyncpathdefault
                            } else {
                                setrsyncpathlocalpath
                            }
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
                                    ToggleView("None", $usersettings.nologging.onChange {
                                        usersettings.inputchangedbyuser = true
                                        if usersettings.nologging == true {
                                            usersettings.minimumlogging = false
                                            usersettings.fulllogging = false
                                        } else {
                                            usersettings.minimumlogging = true
                                            usersettings.fulllogging = false
                                        }
                                    })

                                    ToggleView("Min", $usersettings.minimumlogging.onChange {
                                        usersettings.inputchangedbyuser = true
                                        if usersettings.minimumlogging == true {
                                            usersettings.nologging = false
                                            usersettings.fulllogging = false
                                        }
                                    })

                                    ToggleView("Full", $usersettings.fulllogging.onChange {
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
                                    ToggleView("Detailed", $usersettings.detailedlogging.onChange {
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
                            ToggleView("Monitor network", $usersettings.monitornetworkconnection.onChange {
                                usersettings.inputchangedbyuser = true
                            })

                            ToggleView("Check data", $usersettings.checkinput.onChange {
                                usersettings.inputchangedbyuser = true
                            })
                        }
                    }
                    .padding()

                    // For center
                    Spacer()
                }

                if backup == true {
                    AlertToast(type: .complete(Color.green),
                               title: Optional("Saved"), subTitle: Optional(""))
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
                Spacer()

                // Backup configuration files
                Button("Backup") { backupuserconfigs() }
                    .buttonStyle(PrimaryButtonStyle())

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

    // Rsync
    var headerrsync: some View {
        Text("Rsync version and path")
    }

    var setrsyncpathlocalpath: some View {
        EditValue(250, nil, $usersettings.localrsyncpath.onChange {
            usersettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                usersettings.localrsyncpath = SetandValidatepathforrsync().getpathforrsync()
            })
    }

    var setrsyncpathdefault: some View {
        EditValue(250, SetandValidatepathforrsync().getpathforrsync(), $usersettings.localrsyncpath)
    }

    // Restore path
    var headerpathforrestore: some View {
        Text("Path for restore")
    }

    var setpathforrestore: some View {
        EditValue(250, "Path for restore", $usersettings.temporarypathforrestore.onChange {
            usersettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    usersettings.temporarypathforrestore = pathforrestore
                }
            })
    }

    // Logging
    var headerloggingtofile: some View {
        Text("Log to file")
    }

    // Detail of logging
    var headerdetailedlogging: some View {
        Text("Level log")
    }

    // Header other settings
    var headerothersettings: some View {
        Text("Other settings")
    }

    // Header user setting
    var headerusersetting: some View {
        Text("Save settings")
    }

    // Header backup
    var headermarkdays: some View {
        Text("Mark days")
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
        _ = WriteUserConfigurationPLIST()
    }

    func backupuserconfigs() {
        _ = Backupconfigfiles()
        backup = true
    }
}
