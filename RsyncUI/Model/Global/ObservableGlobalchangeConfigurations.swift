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
        whatischanged.removeAll()
    }
    
    func replaceoccurenceof(_ string: String, with newString: String) -> String {
        return string.replacingOccurrences(of: "\\(newString)", with: "\\\\\(newString)")
    }
    
    func updateglobalchangedconfigurations() {
        guard whatischanged.isEmpty == false else { return }
        
        for element in whatischanged {
            print(element)
            switch element {
            case .localcatalog: break
            case .remotecatalog: break
            case .remoteuser:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.offsiteUsername
                    if occurence_remoteuser.contains("$") {
                        let trimmed = occurence_remoteuser.replacingOccurrences(of: " ", with: "")
                        let split = trimmed.split(separator: "$")
                        guard split.count == 2 else { return task }
                        let newstring = oldsstring.replacingOccurrences(of: split[0], with: split[1])
                        var newtask = task
                        newtask.offsiteUsername = newstring
                        return newtask
                    } else {
                        let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteuser)
                        var newtask = task
                        newtask.offsiteUsername = newstring
                        return newtask
                    }
                }
            case .remoteserver:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.offsiteServer
                    if occurence_remoteserver.contains("$") {
                        let trimmed = occurence_remoteserver.replacingOccurrences(of: " ", with: "")
                        let split = trimmed.split(separator: "$")
                        guard split.count == 2 else { return task }
                        let newstring = oldsstring.replacingOccurrences(of: split[0], with: split[1])
                        var newtask = task
                        newtask.offsiteServer = newstring
                        return newtask
                    } else {
                        let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteserver)
                        var newtask = task
                        newtask.offsiteServer = newstring
                        return newtask
                    }
                }
            case .backupID: break
            }
        }
        resetform()
    }
}

// swiftlint:enable line_length
