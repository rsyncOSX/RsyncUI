import OSLog
import SwiftUI

struct RsyncandPathsettings: View {
    @State private var usersettings = ObservableUsersetting()
    @State private var showthumbsup: Bool = false
    @State private var settingsischanged: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    ToggleViewDefault(text: NSLocalizedString("Rsync v3.x", comment: ""),
                                      binding: $usersettings.rsyncversion3)
                        .onChange(of: usersettings.rsyncversion3) {
                            Task {
                                try await Task.sleep(seconds: 2)
                                if SharedReference.shared.norsync {
                                    SharedReference.shared.localrsyncpath = nil
                                    SharedReference.shared.rsyncversion3 = false
                                    usersettings.localrsyncpath = ""
                                } else {
                                    SharedReference.shared.rsyncversion3 = usersettings.rsyncversion3
                                    SharedReference.shared.localrsyncpath = nil
                                }
                                Rsyncversion().getrsyncversion()
                                settingsischanged = true
                            }
                        }
                        .onChange(of: usersettings.localrsyncpath) {
                            Task {
                                try await Task.sleep(seconds: 2)
                                SharedReference.shared.localrsyncpath = usersettings.localrsyncpath
                                usersettings.setandvalidatepathforrsync(usersettings.localrsyncpath)
                                Rsyncversion().getrsyncversion()
                                settingsischanged = true
                            }
                        }

                    ToggleViewDefault(text: NSLocalizedString("Apple Silicon", comment: ""),
                                      binding: $usersettings.macosarm)
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
        EditValue(400, nil, $usersettings.localrsyncpath)
    }

    var setrsyncpathdefault: some View {
        EditValue(400, SetandValidatepathforrsync().getpathforrsync(), $usersettings.localrsyncpath)
    }

    var setpathforrestore: some View {
        EditValue(400, NSLocalizedString("Path for restore", comment: ""),
                  $usersettings.temporarypathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    usersettings.temporarypathforrestore = pathforrestore
                }
            })
            .onChange(of: usersettings.temporarypathforrestore) {
                Task {
                    try await Task.sleep(seconds: 1)
                    usersettings.setandvalidapathforrestore(usersettings.temporarypathforrestore)
                }
            }
    }

    var setmarkdays: some View {
        EditValue(400, NSLocalizedString("", comment: ""),
                  $usersettings.marknumberofdayssince)
            .onChange(of: usersettings.marknumberofdayssince) {
                Task {
                    try await Task.sleep(seconds: 1)
                    usersettings.markdays(days: usersettings.marknumberofdayssince)
                }
            }
    }
}
