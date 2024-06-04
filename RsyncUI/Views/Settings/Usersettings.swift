//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import OSLog
import SwiftUI

struct Usersettings: View {
    @Environment(AlertError.self) private var alerterror
    @State private var usersettings = ObservableUsersetting()
    @State private var rsyncversion = Rsyncversion()
    @State private var configurationsarebackedup: Bool = false
    // Rsync paths
    @State private var defaultpathrsync = SetandValidatepathforrsync().getpathforrsync()

    var body: some View {
        Form {
            // VStack(alignment: .leading) {
            Section {
                HStack {
                    ToggleViewDefault(NSLocalizedString("Rsync v3.x", comment: ""),
                                      $usersettings.rsyncversion3)
                        .onChange(of: usersettings.rsyncversion3) {
                            SharedReference.shared.rsyncversion3 = usersettings.rsyncversion3
                            rsyncversion.getrsyncversion()
                            defaultpathrsync = SetandValidatepathforrsync().getpathforrsync()
                        }

                    ToggleViewDefault(NSLocalizedString("Apple Silicon", comment: ""),
                                      $usersettings.macosarm)
                        .onChange(of: usersettings.macosarm) {
                            SharedReference.shared.macosarm = usersettings.macosarm
                        }
                        .disabled(true)
                }
            } header: {
                Text("Version rsync")
            }

            Section {
                if usersettings.localrsyncpath.isEmpty == true {
                    setrsyncpathdefault
                } else {
                    setrsyncpathlocalpath
                }
            } header: {
                Text("Path rsync")
            }

            Section {
                setpathforrestore
            } header: {
                Text("Path for restore")
            }

            Section {
                HStack {
                    Text("Days :")

                    TextField("",
                              text: $usersettings.marknumberofdayssince)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 45)
                        .lineLimit(1)
                        .onChange(of: usersettings.marknumberofdayssince) {
                            usersettings.markdays(days: usersettings.marknumberofdayssince)
                        }
                }
            } header: {
                Text("Mark days")
            }

            // VStack(alignment: .leading) {
            Section {
                ToggleViewDefault(NSLocalizedString("Monitor network", comment: ""), $usersettings.monitornetworkconnection)
                    .onChange(of: usersettings.monitornetworkconnection) {
                        SharedReference.shared.monitornetworkconnection = usersettings.monitornetworkconnection
                    }
                ToggleViewDefault(NSLocalizedString("Check for error in output", comment: ""), $usersettings.checkforerrorinrsyncoutput)
                    .onChange(of: usersettings.checkforerrorinrsyncoutput) {
                        SharedReference.shared.checkforerrorinrsyncoutput = usersettings.checkforerrorinrsyncoutput
                    }
                ToggleViewDefault(NSLocalizedString("Add summary to logfile", comment: ""), $usersettings.detailedlogging)
                    .onChange(of: usersettings.detailedlogging) {
                        SharedReference.shared.detailedlogging = usersettings.detailedlogging
                    }
                ToggleViewDefault(NSLocalizedString("Log summary to file", comment: ""),
                                  $usersettings.logtofile)
                    .onChange(of: usersettings.logtofile) {
                        SharedReference.shared.logtofile = usersettings.logtofile
                    }

                if SharedReference.shared.rsyncversion3 {
                    ToggleViewDefault(NSLocalizedString("Confirm execute", comment: ""), $usersettings.confirmexecute)
                        .onChange(of: usersettings.confirmexecute) {
                            SharedReference.shared.confirmexecute = usersettings.confirmexecute
                        }
                }
            } header: {
                Text("Other settings")
            }
            // }
        }
        .formStyle(.grouped)
        .alert(isPresented: $usersettings.alerterror,
               content: { Alert(localizedError: usersettings.error)
               })
        .toolbar {
            ToolbarItem {
                Button {
                    _ = Backupconfigfiles()
                    configurationsarebackedup = true
                    Task {
                        try await Task.sleep(seconds: 2)
                        configurationsarebackedup = false
                    }

                } label: {
                    Image(systemName: "wrench.adjustable.fill")
                        .foregroundColor(Color(.blue))
                        .imageScale(.large)
                }
                .help("Backup configurations")
            }

            ToolbarItem {
                if SharedReference.shared.settingsischanged && usersettings.ready { thumbsupgreen }
            }

            ToolbarItem {
                if configurationsarebackedup { thumbsupgreen }
            }
        }
        .onAppear(perform: {
            Task {
                try await Task.sleep(seconds: 1)
                Logger.process.info("Usersettings is DEFAULT")
                SharedReference.shared.settingsischanged = false
                usersettings.ready = true
            }
        })
        .onChange(of: SharedReference.shared.settingsischanged) {
            guard SharedReference.shared.settingsischanged == true,
                  usersettings.ready == true else { return }
            Task {
                try await Task.sleep(seconds: 1)
                _ = WriteUserConfigurationJSON(UserConfiguration())
                SharedReference.shared.settingsischanged = false
                Logger.process.info("Usersettings is SAVED")
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }

    var setrsyncpathlocalpath: some View {
        EditValue(250, nil, $usersettings.localrsyncpath)
            .onAppear(perform: {
                usersettings.localrsyncpath = SetandValidatepathforrsync().getpathforrsync()
            })
    }

    var setrsyncpathdefault: some View {
        EditValue(250, defaultpathrsync, $usersettings.localrsyncpath)
            .onChange(of: usersettings.localrsyncpath) {
                usersettings.setandvalidatepathforrsync(usersettings.localrsyncpath)
            }
    }

    var setpathforrestore: some View {
        EditValue(250, NSLocalizedString("Path for restore", comment: ""),
                  $usersettings.temporarypathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    usersettings.temporarypathforrestore = pathforrestore
                }
            })
            .onChange(of: usersettings.temporarypathforrestore) {
                usersettings.setandvalidapathforrestore(usersettings.temporarypathforrestore)
            }
    }

    // Header user setting
    var headerusersetting: some View {
        Text("Save settings")
    }
}

// swiftlint:enable line_length
