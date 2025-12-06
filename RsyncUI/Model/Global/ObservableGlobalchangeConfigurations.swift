//
//  ObservableGlobalchangeConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//

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
    // Selecte UUIDS for change
    var selecteduuids = Set<SynchronizeConfiguration.ID>()

    func resetForm() {
        occurence_localcatalog = ""
        replace_localcatalog = ""
        occurence_remotecatalog = ""
        replace_remotecatalog = ""
        occurence_remoteuser = ""
        occurence_remoteserver = ""
        occurence_backupID = ""
        replace_backupID = ""
        whatischanged.removeAll()
        selecteduuids.removeAll()
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
                    if selecteduuids.contains(task.id) || selecteduuids.isEmpty {
                        var newtask = task
                        newtask.backupID = updatestring(update: replace_backupID,
                                                        replace: occurence_backupID,
                                                        original: task.backupID)
                        return newtask
                    } else {
                        return task
                    }
                }
            case .localcatalog:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    if selecteduuids.contains(task.id) || selecteduuids.isEmpty {
                        var newtask = task
                        newtask.localCatalog = updatestring(update: replace_localcatalog,
                                                            replace: occurence_localcatalog,
                                                            original: task.localCatalog)
                        return newtask
                    } else {
                        return task
                    }
                }
            case .remotecatalog:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    if selecteduuids.contains(task.id) || selecteduuids.isEmpty {
                        var newtask = task
                        newtask.offsiteCatalog = updatestring(update: replace_remotecatalog,
                                                              replace: occurence_remotecatalog,
                                                              original: task.offsiteCatalog)
                        return newtask
                    } else {
                        return task
                    }
                }
            case .remoteuser:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    if selecteduuids.contains(task.id) || selecteduuids.isEmpty {
                        let oldsstring = task.offsiteUsername
                        let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteuser)
                        var newtask = task
                        newtask.offsiteUsername = newstring
                        return newtask
                    } else {
                        return task
                    }
                }
            case .remoteserver:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    if selecteduuids.contains(task.id) || selecteduuids.isEmpty {
                        let oldsstring = task.offsiteServer
                        let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteserver)
                        var newtask = task
                        newtask.offsiteServer = newstring
                        return newtask
                    } else {
                        return task
                    }
                }
            }
        }
        resetForm()
    }
}
