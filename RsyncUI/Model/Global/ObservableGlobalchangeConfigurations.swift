//
//  ObservableGlobalchangeConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint:disable line_length

import Foundation
import Observation

enum GlobalchangeConfiguration: String, Codable {
    case localcatalog
    case remotecatalog
    case remoteuser
    case remoteserver
    case backupID
}

@Observable @MainActor
final class ObservableGlobalchangeConfigurations {
    var occurence_backupID: String = ""
    var replace_backupID: String = ""
    var occurence_localcatalog: String = ""
    var replace_localcatalog: String = ""
    var occurence_remotecatalog: String = ""
    var replace_remotecatalog: String = ""
    var occurence_remoteuser: String = ""
    var occurence_remoteserver: String = ""

    var showAlertforupdate: Bool = false
    var whatischanged: Set<GlobalchangeConfiguration> = []
    var globalchangedconfigurations: [SynchronizeConfiguration]?
    // Not changed snapshots, but if snapshots then merge with globalchangedconfigurations
    var notchangedsnapshotconfigurations: [SynchronizeConfiguration]?

    func resetform() {
        occurence_localcatalog = ""
        replace_localcatalog = ""
        occurence_remotecatalog = ""
        replace_remotecatalog = ""
        occurence_remoteuser = ""
        occurence_remoteserver = ""
        occurence_backupID = ""
        replace_backupID = ""
        whatischanged.removeAll()
    }

    func updatestring(update: String, replace: String, original: String) -> String {
        guard update.isEmpty == false else { return original }
        guard replace.isEmpty == false else { return original }
        return original.replacingOccurrences(of: replace, with: update)
    }

    func updateglobalchangedconfigurations() {
        guard whatischanged.isEmpty == false else { return }

        for element in whatischanged {
            switch element {
            case .backupID:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    var newtask = task
                    newtask.backupID = updatestring(update: replace_backupID,
                                                    replace: occurence_backupID,
                                                    original: task.backupID)
                    return newtask
                }
            case .localcatalog:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    var newtask = task
                    newtask.localCatalog = updatestring(update: replace_localcatalog,
                                                        replace: occurence_localcatalog,
                                                        original: task.localCatalog)
                    return newtask
                }
            case .remotecatalog:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    var newtask = task
                    newtask.offsiteCatalog = updatestring(update: replace_remotecatalog,
                                                          replace: occurence_remotecatalog,
                                                          original: task.offsiteCatalog)
                    return newtask
                }
            case .remoteuser:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.offsiteUsername
                    let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteuser)
                    var newtask = task
                    newtask.offsiteUsername = newstring
                    return newtask
                }
            case .remoteserver:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.offsiteServer
                    let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteserver)
                    var newtask = task
                    newtask.offsiteServer = newstring
                    return newtask
                }
            }
        }
        resetform()
    }
}

// swiftlint:enable line_length
