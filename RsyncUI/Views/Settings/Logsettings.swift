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
        _ = WriteUserConfigurationJSON(UserConfiguration())
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
                    ToggleViewDefault(text: "Add summary logrecord", binding: $logsettings.addsummarylogrecord)
                        .onChange(of: logsettings.addsummarylogrecord) {
                            SharedReference.shared.addsummarylogrecord = logsettings.addsummarylogrecord
                            saveConfiguration()
                        }
                    ToggleViewDefault(text: "No time delay Synchronize URL-actions", binding: $logsettings.synchronizewithouttimedelay)
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
                    ToggleViewDefault(text: "Always present the summarized estimate view",
                                      binding: $logsettings.alwaysshowestimateddetailsview)
                        .onChange(of: logsettings.alwaysshowestimateddetailsview) {
                            SharedReference.shared.alwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                            togglealwaysshowestimateddetailsview = logsettings.alwaysshowestimateddetailsview
                            saveConfiguration()
                        }

                    ToggleViewDefault(text: "Silence missing stats",
                                      binding: $logsettings.silencemissingstats)
                        .onChange(of: logsettings.silencemissingstats) {
                            SharedReference.shared.silencemissingstats = logsettings.silencemissingstats
                            togglesilencemissingstats = logsettings.silencemissingstats
                            saveConfiguration()
                        }

                    ToggleViewDefault(text: "Validate arguments",
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
                        DismissafterMessageView(dismissafter: 2, mytext: "Please restart RsyncUI to take effect")
                    }
                }
        }
        .formStyle(.grouped)
    }
}
