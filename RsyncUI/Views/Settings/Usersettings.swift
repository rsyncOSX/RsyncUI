//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Usersettings: View {
    @SwiftUI.Environment(AlertError.self) private var alerterror
    @StateObject var rsyncversion = Rsyncversion()
    @State private var usersettings = ObserveableUsersetting()
    @State private var backup = false

    var body: some View {
        Form {
            Spacer()

            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        Section(header: headerrsync) {
                            HStack {
                                ToggleViewDefault(NSLocalizedString("Rsync v3.x", comment: ""),
                                                  $usersettings.rsyncversion3.onChange {
                                                      SharedReference.shared.rsyncversion3 = usersettings.rsyncversion3

                                                  })
                                ToggleViewDefault(NSLocalizedString("Apple Silicon", comment: ""),
                                                  $usersettings.macosarm.onChange {
                                                      SharedReference.shared.macosarm = usersettings.macosarm
                                                  })
                            }
                        }

                        if usersettings.localrsyncpath.isEmpty == true {
                            setrsyncpathdefault
                        } else {
                            setrsyncpathlocalpath
                        }

                        Section(header: headerpathforrestore) {
                            setpathforrestore
                        }

                        Section(header: headermarkdays) {
                            setmarkdays
                        }

                    }.padding()

                    // Column 2
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading) {
                                Section(header: headerloggingtofile) {
                                    ToggleViewDefault(NSLocalizedString("None", comment: ""),
                                                      $usersettings.nologging.onChange {
                                                          if usersettings.nologging == true {
                                                              usersettings.minimumlogging = false
                                                              usersettings.fulllogging = false
                                                          } else {
                                                              usersettings.minimumlogging = true
                                                              usersettings.fulllogging = false
                                                          }
                                                          SharedReference.shared.fulllogging = usersettings.fulllogging
                                                          SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                                          SharedReference.shared.nologging = usersettings.nologging
                                                      })

                                    ToggleViewDefault(NSLocalizedString("Min", comment: ""),
                                                      $usersettings.minimumlogging.onChange {
                                                          if usersettings.minimumlogging == true {
                                                              usersettings.nologging = false
                                                              usersettings.fulllogging = false
                                                          }
                                                          SharedReference.shared.fulllogging = usersettings.fulllogging
                                                          SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                                          SharedReference.shared.nologging = usersettings.nologging
                                                      })

                                    ToggleViewDefault(NSLocalizedString("Full", comment: ""),
                                                      $usersettings.fulllogging.onChange {
                                                          if usersettings.fulllogging == true {
                                                              usersettings.nologging = false
                                                              usersettings.minimumlogging = false
                                                          }
                                                          SharedReference.shared.fulllogging = usersettings.fulllogging
                                                          SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                                          SharedReference.shared.nologging = usersettings.nologging
                                                      })
                                }
                            }

                            VStack(alignment: .leading) {
                                Section(header: othersettings) {
                                    ToggleViewDefault(NSLocalizedString("Detailed log level", comment: ""), $usersettings.detailedlogging.onChange {
                                        SharedReference.shared.detailedlogging = usersettings.detailedlogging
                                    })
                                    ToggleViewDefault(NSLocalizedString("Monitor network", comment: ""), $usersettings.monitornetworkconnection.onChange {
                                        SharedReference.shared.monitornetworkconnection = usersettings.monitornetworkconnection
                                    })
                                }
                            }
                        }
                    }.padding()

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
                Spacer()

                // Backup configuration files
                Button("Backup") { backupuserconfigs() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Save") { saveusersettings() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .lineSpacing(2)
        .padding()
        .alert(isPresented: $usersettings.alerterror,
               content: { Alert(localizedError: usersettings.error)
               })
    }

    // Rsync
    var headerrsync: some View {
        Text("Rsync version and path")
    }

    var setrsyncpathlocalpath: some View {
        EditValue(250, nil, $usersettings.localrsyncpath)
            .onAppear(perform: {
                usersettings.localrsyncpath = SetandValidatepathforrsync().getpathforrsync()
            })
    }

    var setrsyncpathdefault: some View {
        EditValue(250, SetandValidatepathforrsync().getpathforrsync(),
                  $usersettings.localrsyncpath.onChange {
                      usersettings.setandvalidatepathforrsync(usersettings.localrsyncpath)
                  })
    }

    // Restore path
    var headerpathforrestore: some View {
        Text("Path for restore")
    }

    var setpathforrestore: some View {
        EditValue(250, NSLocalizedString("Path for restore", comment: ""),
                  $usersettings.temporarypathforrestore.onChange {
                      usersettings.setandvalidapathforrestore(usersettings.temporarypathforrestore)
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
    var othersettings: some View {
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
        TextField("",
                  text: $usersettings.marknumberofdayssince.onChange {
                      usersettings.markdays(days: usersettings.marknumberofdayssince)
                  })
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                  .frame(width: 70)
                  .lineLimit(1)
    }
}

extension Usersettings {
    func saveusersettings() {
        _ = WriteUserConfigurationJSON(UserConfiguration())
        // Update the rsync version string
        Task {
            await rsyncversion.getrsyncversion()
        }
        backup = true
    }

    func backupuserconfigs() {
        _ = Backupconfigfiles()
        backup = true
    }
}

// swiftlint:enable line_length
