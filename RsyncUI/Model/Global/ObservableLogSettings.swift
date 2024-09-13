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
    var logtofile: Bool = SharedReference.shared.logtofile
    // Check for network changes
    var monitornetworkconnection: Bool = SharedReference.shared.monitornetworkconnection
    // True if on ARM based Mac
    var macosarm: Bool = SharedReference.shared.macosarm
    // Check for "error" in output from rsync
    var checkforerrorinrsyncoutput: Bool = SharedReference.shared.checkforerrorinrsyncoutput
    // Automatic execution of estimated tasks
    var confirmexecute: Bool = SharedReference.shared.confirmexecute

}
