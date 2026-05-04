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

    /// Helper function to keep the save logic in one place
    private func saveConfiguration() {
        let snapshot = UserConfiguration()
        Task { @MainActor in
            await WriteUserConfigurationJSON.write(snapshot)
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Version rsync")
                .font(.title3)
                .fontWeight(.bold)) {
                    HStack {
                        ToggleViewDefault(text: "Rsync v3.x",
                                          binding: $rsyncpathsettings.rsyncversion3)
                            .onChange(of: rsyncpathsettings.rsyncversion3) {
                                if SharedReference.shared.norsync {
                                    SharedReference.shared.localrsyncpath = nil
                                    SharedReference.shared.rsyncversion3 = false
                                    rsyncpathsettings.localrsyncpath = ""
                                } else {
                                    SharedReference.shared.rsyncversion3 = rsyncpathsettings.rsyncversion3
                                    SharedReference.shared.localrsyncpath = nil
                                    rsyncpathsettings.localrsyncpath = ""
                                }
                                Rsyncversion().getRsyncVersion()
                                saveConfiguration()
                            }

                        ToggleViewDefault(text: "Apple Silicon",
                                          binding: $rsyncpathsettings.macosarm)
                            .onChange(of: rsyncpathsettings.macosarm) {
                                SharedReference.shared.macosarm = rsyncpathsettings.macosarm
                            }
                            .disabled(true)
                    }
                }

            Section(header: Text("Path rsync")
                .font(.title3)
                .fontWeight(.bold)) {
                    if rsyncpathsettings.localrsyncpath.isEmpty == true {
                        setrsyncpathdefault
                    } else {
                        setrsyncpathlocalpath
                    }
                }

            Section(header: Text("Path for restore")
                .font(.title3)
                .fontWeight(.bold)) {
                    HStack {
                        setpathforrestore

                        OpencatalogView(selecteditem: $rsyncpathsettings.temporarypathforrestore, catalogs: true)
                    }
                }

            Section(header: Text("Mark days after")
                .font(.title3)
                .fontWeight(.bold)) {
                    setmarkdays
                }

            Section(header: Text("Backup configurations")
                .font(.title3)
                .fontWeight(.bold)) {
                    HStack {
                        ConditionalGlassButton(
                            systemImage: "wrench.adjustable.fill",
                            text: "Backup",
                            helpText: "Backup configurations"
                        ) {
                            _ = Backupconfigfiles()
                        }
                    }
                }
        }
        .formStyle(.grouped)
    }

    var setrsyncpathlocalpath: some View {
        EditValueErrorScheme(
            400,
            nil,
            $rsyncpathsettings.localrsyncpath,
            rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath)
        )
        .foregroundStyle(rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath) ? Color.white : Color.red)
        .onChange(of: rsyncpathsettings.localrsyncpath) {
            guard rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath) else {
                return
            }
            SharedReference.shared.localrsyncpath = rsyncpathsettings.localrsyncpath
            if rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath),
               rsyncpathsettings.setandvalidatepathforrsync(rsyncpathsettings.localrsyncpath) {
                Rsyncversion().getRsyncVersion()
            }
            saveConfiguration()
        }
    }

    var setrsyncpathdefault: some View {
        EditValueScheme(
            400,
            SetandValidatepathforrsync().getpathforrsync(rsyncpathsettings.rsyncversion3),
            $rsyncpathsettings.localrsyncpath
        )
    }

    var setpathforrestore: some View {
        EditValueErrorScheme(
            400,
            "Path for restore",
            $rsyncpathsettings.temporarypathforrestore,
            rsyncpathsettings.verifyPathForRestore(rsyncpathsettings.temporarypathforrestore)
        )
        .foregroundStyle(rsyncpathsettings.verifyPathForRestore(rsyncpathsettings.temporarypathforrestore) ?
            Color.white : Color.red)
        .onAppear {
            if let pathforrestore = SharedReference.shared.pathforrestore {
                rsyncpathsettings.temporarypathforrestore = pathforrestore
            }
        }
        .onChange(of: rsyncpathsettings.temporarypathforrestore) {
            guard rsyncpathsettings.verifyPathForRestore(rsyncpathsettings.temporarypathforrestore) else {
                return
            }
            if rsyncpathsettings.temporarypathforrestore.hasSuffix("/") == false {
                rsyncpathsettings.temporarypathforrestore.append("/")
            }
            SharedReference.shared.pathforrestore = rsyncpathsettings.temporarypathforrestore
            saveConfiguration()
        }
    }

    var setmarkdays: some View {
        EditValueErrorScheme(
            400,
            "",
            $rsyncpathsettings.marknumberofdayssince,
            rsyncpathsettings.verifystringtoint(rsyncpathsettings.marknumberofdayssince)
        )
        .foregroundStyle(rsyncpathsettings.verifystringtoint(rsyncpathsettings.marknumberofdayssince) ? Color.white : Color.red)
        .onChange(of: rsyncpathsettings.marknumberofdayssince) {
            guard rsyncpathsettings.verifystringtoint(rsyncpathsettings.marknumberofdayssince) else {
                return
            }
            rsyncpathsettings.markdays(days: rsyncpathsettings.marknumberofdayssince)
            saveConfiguration()
        }
    }
}
