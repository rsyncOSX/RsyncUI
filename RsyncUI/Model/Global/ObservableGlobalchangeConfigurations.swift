//
//  ObservableGlobalchangeConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint:disable line_length

import Foundation
import Observation

@Observable @MainActor
final class ObservableGlobalchangeConfigurations {
    var localcatalog: String = ""
    var remotecatalog: String = ""
    var remoteuser: String = ""
    var remoteserver: String = ""
    var backupID: String = ""

    var showAlertforupdate: Bool = false

    var globalchangedconfigurations: [SynchronizeConfiguration]?

    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
        backupID = ""
    }
}

// swiftlint:enable line_length
