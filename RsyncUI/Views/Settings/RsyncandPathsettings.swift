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

    var body: some View {
        Form {
            Section(header: Text("Version rsync")
                .font(.title3)
                .fontWeight(.bold))
            {
                HStack {
                    ToggleViewDefault(text: NSLocalizedString("Rsync v3.x", comment: ""),
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
                            Rsyncversion().getrsyncversion()
                        }

                    ToggleViewDefault(text: NSLocalizedString("Apple Silicon", comment: ""),
                                      binding: $rsyncpathsettings.macosarm)
                        .onChange(of: rsyncpathsettings.macosarm) {
                            SharedReference.shared.macosarm = rsyncpathsettings.macosarm
                        }
                        .disabled(true)
                }
            }

            Section(header: Text("Path rsync")
                .font(.title3)
                .fontWeight(.bold))
            {
                if rsyncpathsettings.localrsyncpath.isEmpty == true {
                    setrsyncpathdefault
                } else {
                    setrsyncpathlocalpath
                }
            }

            Section(header: Text("Path for restore")
                .font(.title3)
                .fontWeight(.bold))
            {
                HStack {
                    setpathforrestore

                    OpencatalogView(selecteditem: $rsyncpathsettings.temporarypathforrestore, catalogs: true)
                }
            }

            Section(header: Text("Mark days after")
                .font(.title3)
                .fontWeight(.bold))
            {
                setmarkdays
            }

            Section(header: Text("Backup configurations & Save userconfiguration")
                .font(.title3)
                .fontWeight(.bold))
            {
                HStack {
                    ConditionalGlassButton(
                        systemImage: "wrench.adjustable.fill",
                        text: "Backup configurations",
                        helpText: "Backup configurations"
                    ) {
                        _ = Backupconfigfiles()
                    }

                    ConditionalGlassButton(
                        systemImage: "square.and.arrow.down",
                        text: "Save",
                        helpText: "Save userconfiguration"
                    ) {
                        _ = WriteUserConfigurationJSON(UserConfiguration())
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    var setrsyncpathlocalpath: some View {
        EditValueErrorScheme(400, nil, $rsyncpathsettings.localrsyncpath,
                             rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath))
            .foregroundColor(rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath) ? Color.white : Color.red)
            .onChange(of: rsyncpathsettings.localrsyncpath) {
                guard rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath) else {
                    return
                }
                SharedReference.shared.localrsyncpath = rsyncpathsettings.localrsyncpath
                if rsyncpathsettings.verifypathforrsync(rsyncpathsettings.localrsyncpath),
                   rsyncpathsettings.setandvalidatepathforrsync(rsyncpathsettings.localrsyncpath)
                {
                    Rsyncversion().getrsyncversion()
                }
            }
    }

    var setrsyncpathdefault: some View {
        EditValueScheme(400, SetandValidatepathforrsync().getpathforrsync(rsyncpathsettings.rsyncversion3), $rsyncpathsettings.localrsyncpath)
    }

    var setpathforrestore: some View {
        EditValueErrorScheme(400, NSLocalizedString("Path for restore", comment: ""),
                             $rsyncpathsettings.temporarypathforrestore,
                             rsyncpathsettings.verifypathforrestore(rsyncpathsettings.temporarypathforrestore))
            .foregroundColor(rsyncpathsettings.verifypathforrestore(rsyncpathsettings.temporarypathforrestore) ? Color.white : Color.red)
            .onAppear {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    rsyncpathsettings.temporarypathforrestore = pathforrestore
                }
            }
            .onChange(of: rsyncpathsettings.temporarypathforrestore) {
                guard rsyncpathsettings.verifypathforrestore(rsyncpathsettings.temporarypathforrestore) else {
                    return
                }
                if rsyncpathsettings.temporarypathforrestore.hasSuffix("/") == false {
                    rsyncpathsettings.temporarypathforrestore.append("/")
                }
                SharedReference.shared.pathforrestore = rsyncpathsettings.temporarypathforrestore
            }
    }

    var setmarkdays: some View {
        EditValueErrorScheme(400, NSLocalizedString("", comment: ""),
                             $rsyncpathsettings.marknumberofdayssince,
                             rsyncpathsettings.verifystringtoint(rsyncpathsettings.marknumberofdayssince))
            .foregroundColor(rsyncpathsettings.verifystringtoint(rsyncpathsettings.marknumberofdayssince) ? Color.white : Color.red)
            .onChange(of: rsyncpathsettings.marknumberofdayssince) {
                guard rsyncpathsettings.verifystringtoint(rsyncpathsettings.marknumberofdayssince) else {
                    return
                }
                rsyncpathsettings.markdays(days: rsyncpathsettings.marknumberofdayssince)
            }
    }
}
