//
//  RsyncandPathsettings 2.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/09/2024.
//

import OSLog
import SwiftUI

struct RsyncandPathsettings: View {
    @State private var rsyncpathsettings = ObservableRsyncPathSetting()
    @State private var showthumbsup: Bool = false
    @State private var settingsischanged: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    ToggleViewDefault(text: NSLocalizedString("Rsync v3.x", comment: ""),
                                      binding: $rsyncpathsettings.rsyncversion3)
                        .onChange(of: rsyncpathsettings.rsyncversion3) {
                            Task {
                                try await Task.sleep(seconds: 2)
                                if SharedReference.shared.norsync {
                                    SharedReference.shared.localrsyncpath = nil
                                    SharedReference.shared.rsyncversion3 = false
                                    rsyncpathsettings.localrsyncpath = ""
                                } else {
                                    SharedReference.shared.rsyncversion3 = rsyncpathsettings.rsyncversion3
                                    SharedReference.shared.localrsyncpath = nil
                                }
                                Rsyncversion().getrsyncversion()
                                settingsischanged = true
                            }
                        }
                        .onChange(of: rsyncpathsettings.localrsyncpath) {
                            Task {
                                try await Task.sleep(seconds: 2)
                                SharedReference.shared.localrsyncpath = rsyncpathsettings.localrsyncpath
                                rsyncpathsettings.setandvalidatepathforrsync(rsyncpathsettings.localrsyncpath)
                                Rsyncversion().getrsyncversion()
                                settingsischanged = true
                            }
                        }

                    ToggleViewDefault(text: NSLocalizedString("Apple Silicon", comment: ""),
                                      binding: $rsyncpathsettings.macosarm)
                        .onChange(of: rsyncpathsettings.macosarm) {
                            SharedReference.shared.macosarm = rsyncpathsettings.macosarm
                        }
                        .disabled(true)
                }
            } header: {
                Text("Version rsync")
            }

            Section {
                if rsyncpathsettings.localrsyncpath.isEmpty == true {
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
                setmarkdays
            } header: {
                Text("Mark days after")
            }

            Section {
                HStack {
                    Button {
                        _ = Backupconfigfiles()
                        showthumbsup = true

                    } label: {
                        Image(systemName: "wrench.adjustable.fill")
                    }
                    .buttonStyle(ColorfulButtonStyle())

                    if showthumbsup { thumbsupgreen }
                }

            } header: {
                Text("Backup configurations")
            }
        }
        .formStyle(.grouped)
        .onChange(of: settingsischanged) {
            guard settingsischanged == true else { return }
            Task {
                try await Task.sleep(seconds: 1)
                _ = WriteUserConfigurationJSON(UserConfiguration())
                Logger.process.info("RsyncAndPath is SAVED")
                showthumbsup = true
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup.fill")
            .foregroundColor(Color(.green))
            .imageScale(.large)
            .onAppear {
                Task {
                    try await Task.sleep(seconds: 2)
                    showthumbsup = false
                    settingsischanged = false
                }
            }
    }

    var setrsyncpathlocalpath: some View {
        EditValue(400, nil, $rsyncpathsettings.localrsyncpath)
    }

    var setrsyncpathdefault: some View {
        EditValue(400, SetandValidatepathforrsync().getpathforrsync(), $rsyncpathsettings.localrsyncpath)
    }

    var setpathforrestore: some View {
        EditValue(400, NSLocalizedString("Path for restore", comment: ""),
                  $rsyncpathsettings.temporarypathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    rsyncpathsettings.temporarypathforrestore = pathforrestore
                }
            })
            .onChange(of: rsyncpathsettings.temporarypathforrestore) {
                Task {
                    try await Task.sleep(seconds: 1)
                    rsyncpathsettings.setandvalidapathforrestore(rsyncpathsettings.temporarypathforrestore)
                }
            }
    }

    var setmarkdays: some View {
        EditValue(400, NSLocalizedString("", comment: ""),
                  $rsyncpathsettings.marknumberofdayssince)
            .onChange(of: rsyncpathsettings.marknumberofdayssince) {
                Task {
                    try await Task.sleep(seconds: 1)
                    rsyncpathsettings.markdays(days: rsyncpathsettings.marknumberofdayssince)
                }
            }
    }
}
