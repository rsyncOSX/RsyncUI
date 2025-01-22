//
//  ObservableLogSettings.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/09/2024.
//

import Foundation
import Observation

@Observable @MainActor
final class ObservableLogSettings: PropogateError {
    // Detailed logging
    var addsummarylogrecord: Bool = SharedReference.shared.addsummarylogrecord
    // Check for network changes
    var monitornetworkconnection: Bool = SharedReference.shared.monitornetworkconnection
    // Check for "error" in output from rsync
    var checkforerrorinrsyncoutput: Bool = SharedReference.shared.checkforerrorinrsyncoutput
    // Automatic execution of estimated tasks
    var confirmexecute: Bool = SharedReference.shared.confirmexecute
    // Synchronize without time delay URL actions
    var synchronizewithouttimedelay: Bool = SharedReference.shared.synchronizewithouttimedelay
    // Toggle sidebar hidden on/off
    var sidebarishidden: Bool = SharedReference.shared.sidebarishidden
}

/*
 enum LogSettings: String, CaseIterable, Identifiable, CustomStringConvertible{

     case addsummarylogrecord = "Monitor network"
     case monitornetworkconnection = "Check for error in output"
     case checkforerrorinrsyncoutput = "Add summary logrecord"
     case confirmexecute = "Confirm execute"
     case synchronizewithouttimedelay = "No time delay Synchronize URL-actions"
     case sidebarishidden = "Hide the Sidebar on startup"

     var id: String { rawValue }
     var description: String { rawValue.localizedCapitalized }
 }
 */
