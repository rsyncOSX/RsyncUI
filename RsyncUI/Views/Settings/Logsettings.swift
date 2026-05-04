//
//  Logsettings.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/06/2024.
//

import OSLog
import SwiftUI

struct Logsettings: View {
    @State private var logsettings = ObservableLogSettings()
    @State private var toggleobservemountedvolumes: Bool = false
    @State private var togglealwaysshowestimateddetailsview: Bool = false
    @State private var togglesilencemissingstats: Bool = false
    @State private var togglevalidatearguments: Bool = false

    /// Helper function to keep the save logic in one place
    private func saveConfiguration() {
        let snapshot = UserConfiguration()
        Task { @MainActor in
            await WriteUserConfigurationJSON.write(snapshot)
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Log settings")
                .font(.title3)
                .fontWeight(.bold)) {
                    ToggleViewDefault(text: "Check for error in output", binding: $logsettings.checkforerrorinrsyncoutput)
                        .onChange(of: logsettings.checkforerrorinrsyncoutput) {
                            SharedReference.shared.checkforerrorinrsyncoutput = logsettings.checkforerrorinrsyncoutput
                            saveConfiguration()
                        }
                    ToggleViewDefault(text: "Add summary log record", binding: $logsettings.addsummarylogrecord)
                        .onChange(of: logsettings.addsummarylogrecord) {
                            SharedReference.shared.addsummarylogrecord = logsettings.addsummarylogrecord
                            saveConfiguration()
                        }
                    ToggleViewDefault(
                        text: "Skip time delay for URL-triggered sync",
                        binding: $logsettings.synchronizewithouttimedelay
                    )
                    .onChange(of: logsettings.synchronizewithouttimedelay) {
                        SharedReference.shared.synchronizewithouttimedelay = logsettings.synchronizewithouttimedelay
                        saveConfiguration()
                    }
                    ToggleViewDefault(text: "Hide the Sidebar on startup", binding: $logsettings.sidebarishidden)
                        .onChange(of: logsettings.sidebarishidden) {
                            SharedReference.shared.sidebarishidden = logsettings.sidebarishidden
                            saveConfiguration()
                        }
                    ToggleViewDefault(text: "Observe mounting of external drives", binding: $logsettings.observemountedvolumes)
                        .onChange(of: logsettings.observemountedvolumes) {
                            SharedReference.shared.observemountedvolumes = logsettings.observemountedvolumes
                            toggleobservemountedvolumes = logsettings.observemountedvolumes
                            saveConfiguration()
                        }
                    ToggleViewDefault(text: "Always show estimate summary",
                                      binding: $logsettings.alwaysshowestimateddetailsview)
                        .onChange(of: logsettings.alwaysshowestimateddetailsview) {
                            SharedReference.shared.alwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                            togglealwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                            saveConfiguration()
                        }

                    ToggleViewDefault(text: "Suppress missing stats warnings",
                                      binding: $logsettings.silencemissingstats)
                        .onChange(of: logsettings.silencemissingstats) {
                            SharedReference.shared.silencemissingstats = logsettings.silencemissingstats
                            togglesilencemissingstats = logsettings.silencemissingstats
                            saveConfiguration()
                        }

                    ToggleViewDefault(text: "Validate rsync arguments",
                                      binding: $logsettings.validatearguments)
                        .onChange(of: logsettings.validatearguments) {
                            SharedReference.shared.validatearguments = logsettings.validatearguments
                            togglevalidatearguments = logsettings.validatearguments
                            saveConfiguration()
                        }

                    if SharedReference.shared.rsyncversion3 {
                        ToggleViewDefault(text: "Confirm execute", binding: $logsettings.confirmexecute)
                            .onChange(of: logsettings.confirmexecute) {
                                SharedReference.shared.confirmexecute = logsettings.confirmexecute
                                saveConfiguration()
                            }
                    }

                    if toggleobservemountedvolumes {
                        DismissafterMessageView(dismissafter: 2, mytext: "Restart RsyncUI for this change to take effect")
                    }
                }
        }
        .formStyle(.grouped)
    }
}
