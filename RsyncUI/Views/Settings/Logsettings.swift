//
//  Logsettings.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/06/2024.
//
// swiftlint:disable line_length

import OSLog
import SwiftUI

struct Logsettings: View {
    @State private var logsettings = ObservableLogSettings()
    @State private var toggleobservemountedvolumes: Bool = false
    @State private var togglealwaysshowestimateddetailsview: Bool = false
    @State private var togglehideverifyremotefunction: Bool = false
    @State private var togglehideschedule: Bool = false

    var body: some View {
        Form {
            Section {
                ToggleViewDefault(text: NSLocalizedString("Monitor network", comment: ""), binding: $logsettings.monitornetworkconnection)
                    .onChange(of: logsettings.monitornetworkconnection) {
                        SharedReference.shared.monitornetworkconnection = logsettings.monitornetworkconnection
                    }
                ToggleViewDefault(text: NSLocalizedString("Check for error in output", comment: ""), binding: $logsettings.checkforerrorinrsyncoutput)
                    .onChange(of: logsettings.checkforerrorinrsyncoutput) {
                        SharedReference.shared.checkforerrorinrsyncoutput = logsettings.checkforerrorinrsyncoutput
                    }
                ToggleViewDefault(text: NSLocalizedString("Add summary logrecord", comment: ""), binding: $logsettings.addsummarylogrecord)
                    .onChange(of: logsettings.addsummarylogrecord) {
                        SharedReference.shared.addsummarylogrecord = logsettings.addsummarylogrecord
                    }
                ToggleViewDefault(text: NSLocalizedString("No time delay Synchronize URL-actions", comment: ""), binding: $logsettings.synchronizewithouttimedelay)
                    .onChange(of: logsettings.synchronizewithouttimedelay) {
                        SharedReference.shared.synchronizewithouttimedelay = logsettings.synchronizewithouttimedelay
                    }
                ToggleViewDefault(text: NSLocalizedString("Hide the Sidebar on startup", comment: ""), binding: $logsettings.sidebarishidden)
                    .onChange(of: logsettings.sidebarishidden) {
                        SharedReference.shared.sidebarishidden = logsettings.sidebarishidden
                    }
                ToggleViewDefault(text: NSLocalizedString("Observe mounting of external drives", comment: ""), binding: $logsettings.observemountedvolumes)
                    .onChange(of: logsettings.observemountedvolumes) {
                        SharedReference.shared.observemountedvolumes = logsettings.observemountedvolumes
                        toggleobservemountedvolumes = logsettings.observemountedvolumes
                    }
                ToggleViewDefault(text: NSLocalizedString("Always present the summarized estimate view", comment: ""), binding: $logsettings.alwaysshowestimateddetailsview)
                    .onChange(of: logsettings.alwaysshowestimateddetailsview) {
                        SharedReference.shared.alwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                        togglealwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                    }

                ToggleViewDefault(text: NSLocalizedString("Hide Verify remote", comment: ""),
                                  binding: $logsettings.hideverifyremotefunction)
                    .onChange(of: logsettings.hideverifyremotefunction) {
                        SharedReference.shared.hideverifyremotefunction = logsettings.hideverifyremotefunction
                        togglehideverifyremotefunction = logsettings.hideverifyremotefunction
                    }

                ToggleViewDefault(text: NSLocalizedString("Hide Schedule", comment: ""),
                                  binding: $logsettings.hideschedule)
                    .onChange(of: logsettings.hideschedule) {
                        SharedReference.shared.hideschedule = logsettings.hideschedule
                        togglehideschedule = logsettings.hideschedule
                    }

                if SharedReference.shared.rsyncversion3 {
                    ToggleViewDefault(text: NSLocalizedString("Confirm execute", comment: ""), binding: $logsettings.confirmexecute)
                        .onChange(of: logsettings.confirmexecute) {
                            SharedReference.shared.confirmexecute = logsettings.confirmexecute
                        }
                }

                if toggleobservemountedvolumes {
                    Text("If switched ON, please restart RsyncUI to take effect")
                }

            } header: {
                Text("Monitor network, error and log settings")
            }

            Section {
                Button {
                    _ = WriteUserConfigurationJSON(UserConfiguration())
                    Logger.process.info("USER CONFIGURATION is SAVED")
                    if logsettings.hideschedule {
                        // Schedule is off, delete any schedules
                        GlobalTimer.shared.clearSchedules()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Save userconfiguration")
                .buttonStyle(ColorfulButtonStyle())
            } header: {
                Text("Save userconfiguration")
            }
        }
        .formStyle(.grouped)
    }
}

// swiftlint:enable line_length
