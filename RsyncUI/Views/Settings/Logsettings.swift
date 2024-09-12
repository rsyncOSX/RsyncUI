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
    @State private var usersettings = ObservableUsersetting()
    @State private var showthumbsup: Bool = false
    @State private var settingsischanged: Bool = false

    var body: some View {
        Form {
            Section {
                ToggleViewDefault(text: NSLocalizedString("Monitor network", comment: ""), binding: $usersettings.monitornetworkconnection)
                    .onChange(of: usersettings.monitornetworkconnection) {
                        SharedReference.shared.monitornetworkconnection = usersettings.monitornetworkconnection
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Check for error in output", comment: ""), binding: $usersettings.checkforerrorinrsyncoutput)
                    .onChange(of: usersettings.checkforerrorinrsyncoutput) {
                        SharedReference.shared.checkforerrorinrsyncoutput = usersettings.checkforerrorinrsyncoutput
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Add summary logrecord", comment: ""), binding: $usersettings.addsummarylogrecord)
                    .onChange(of: usersettings.addsummarylogrecord) {
                        SharedReference.shared.addsummarylogrecord = usersettings.addsummarylogrecord
                        settingsischanged = true
                    }
                ToggleViewDefault(text: NSLocalizedString("Log summary logfile", comment: ""),
                                  binding: $usersettings.logtofile)
                    .onChange(of: usersettings.logtofile) {
                        SharedReference.shared.logtofile = usersettings.logtofile
                        settingsischanged = true
                    }

                if SharedReference.shared.rsyncversion3 {
                    ToggleViewDefault(text: NSLocalizedString("Confirm execute", comment: ""), binding: $usersettings.confirmexecute)
                        .onChange(of: usersettings.confirmexecute) {
                            SharedReference.shared.confirmexecute = usersettings.confirmexecute
                            settingsischanged = true
                        }
                }

                if showthumbsup { thumbsupgreen }

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
