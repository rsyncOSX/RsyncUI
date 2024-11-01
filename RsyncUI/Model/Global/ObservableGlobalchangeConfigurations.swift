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
    var occurence_localcatalog: String = ""
    var occurence_remotecatalog: String = ""
    var occurence_remoteuser: String = ""
    var occurence_remoteserver: String = ""
    var occurence_backupID: String = ""

    var showAlertforupdate: Bool = false
    
    var whatischanged: Set<GlobalchangeConfiguration> = []

    var globalchangedconfigurations: [SynchronizeConfiguration]?

    func resetform() {
        occurence_localcatalog = ""
        occurence_remotecatalog = ""
        occurence_remoteuser = ""
        occurence_remoteserver = ""
        occurence_backupID = ""
    }
    
    func replaceoccurenceof(_ string: String, with newString: String) -> String {
        return string.replacingOccurrences(of: "\\(newString)", with: "\\\\\(newString)")
    }
    
    func updateglobalchangedconfigurations(newString: String) {
        guard whatischanged.isEmpty == false else { return }
        
        
        globalchangedconfigurations = globalchangedconfigurations?.map { task in
            let oldsstring = task.offsiteCatalog
            let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: newString)
            var newtask = task
            newtask.offsiteCatalog = newstring
            return newtask
        }
        
        resetform()
    }
}

// swiftlint:enable line_length
