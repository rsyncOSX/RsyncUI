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
    @State private var showthumbsup: Bool = false
    @State private var settingsischanged: Bool = false
    @State private var toggleobservemountedvolumes: Bool = false
    @State private var togglealwaysshowestimateddetailsview: Bool = false

    var body: some View {
        Form {
            Section {
                ToggleViewDefault(text: NSLocalizedString("Monitor network", comment: ""), binding: $logsettings.monitornetworkconnection)
                    .onChange(of: logsettings.monitornetworkconnection) {
                        SharedReference.shared.monitornetworkconnection = logsettings.monitornetworkconnection
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Check for error in output", comment: ""), binding: $logsettings.checkforerrorinrsyncoutput)
                    .onChange(of: logsettings.checkforerrorinrsyncoutput) {
                        SharedReference.shared.checkforerrorinrsyncoutput = logsettings.checkforerrorinrsyncoutput
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Add summary logrecord", comment: ""), binding: $logsettings.addsummarylogrecord)
                    .onChange(of: logsettings.addsummarylogrecord) {
                        SharedReference.shared.addsummarylogrecord = logsettings.addsummarylogrecord
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("No time delay Synchronize URL-actions", comment: ""), binding: $logsettings.synchronizewithouttimedelay)
                    .onChange(of: logsettings.synchronizewithouttimedelay) {
                        SharedReference.shared.synchronizewithouttimedelay = logsettings.synchronizewithouttimedelay
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Hide the Sidebar on startup", comment: ""), binding: $logsettings.sidebarishidden)
                    .onChange(of: logsettings.sidebarishidden) {
                        SharedReference.shared.sidebarishidden = logsettings.sidebarishidden
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Observe mounting of external drives", comment: ""), binding: $logsettings.observemountedvolumes)
                    .onChange(of: logsettings.observemountedvolumes) {
                        SharedReference.shared.observemountedvolumes = logsettings.observemountedvolumes
                        toggleobservemountedvolumes = logsettings.observemountedvolumes
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Always present the summarized estimate view", comment: ""), binding: $logsettings.alwaysshowestimateddetailsview)
                    .onChange(of: logsettings.alwaysshowestimateddetailsview) {
                        SharedReference.shared.alwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                        togglealwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                        settingsischanged = true
                    }

                if SharedReference.shared.rsyncversion3 {
                    ToggleViewDefault(text: NSLocalizedString("Confirm execute", comment: ""), binding: $logsettings.confirmexecute)
                        .onChange(of: logsettings.confirmexecute) {
                            SharedReference.shared.confirmexecute = logsettings.confirmexecute
                            settingsischanged = true
                        }
                }

                if showthumbsup { thumbsupgreen }
                if toggleobservemountedvolumes {
                    Text("If switched ON, please restart RsyncUI to take effect")
                }

            } header: {
                Text("Monitor network, error and log settings")
            }
        }
        .formStyle(.grouped)
        .onChange(of: settingsischanged) {
            guard settingsischanged == true else { return }
            Task {
                try await Task.sleep(seconds: 1)
                _ = WriteUserConfigurationJSON(UserConfiguration())
                Logger.process.info("Monitor network, error and log settings is SAVED")
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
}

// swiftlint:enable line_length
