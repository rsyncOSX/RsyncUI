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

    var body: some View {
        Form {
            Section(header: Text("Monitor network, error and log settings")
                .font(.title3)
                .fontWeight(.bold))
            {
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

                if SharedReference.shared.rsyncversion3 {
                    ToggleViewDefault(text: NSLocalizedString("Confirm execute", comment: ""), binding: $logsettings.confirmexecute)
                        .onChange(of: logsettings.confirmexecute) {
                            SharedReference.shared.confirmexecute = logsettings.confirmexecute
                        }
                }

                if toggleobservemountedvolumes {
                    DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("Please restart RsyncUI to take effect", comment: ""))
                }

                if togglehideverifyremotefunction {
                    DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("Please restart RsyncUI to take effect", comment: ""))
                }
            }

            Section(header: Text("Save userconfiguration")
                .font(.title3)
                .fontWeight(.bold))
            {
                ConditionalGlassButton(
                    systemImage: "square.and.arrow.down",
                    text: "Save",
                    helpText: "Save userconfiguration"
                ) {
                    _ = WriteUserConfigurationJSON(UserConfiguration())
                }
            }
        }
        .formStyle(.grouped)
    }

    private func deleteschedulefile() {
        let path = Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let fullpathscheduleString = fullpathmacserial.appending("/") + SharedConstants().caldenarfilejson
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().caldenarfilejson)

            guard fm.locationExists(at: fullpathscheduleString, kind: .file) == true else {
                return
            }
            do {
                try fm.removeItem(at: profileURL)
            } catch let e {
                let error = e as NSError
                path.propogateerror(error: error)
            }
        }
    }
}

// swiftlint:enable line_length
