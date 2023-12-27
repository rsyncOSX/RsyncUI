//
//  Assist.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/12/2022.
//

import Foundation
import OSLog

struct ServerUser: Identifiable, Hashable {
    let id = UUID()
    var name: String?
}

@Observable
final class Assist {
    // @ObservationIgnored
    // var catalogs = Set<String>()
    @ObservationIgnored
    var remoteservers = [ServerUser]()
    @ObservationIgnored
    var remoteusers = [ServerUser]()
    // var nameandpaths: NamesandPaths?

    func setserversandlogins(_ configurations: [Configuration]?) {
        guard configurations != nil else { return }
        for i in 0 ..< (configurations?.count ?? 0) {
            if let config = configurations?[i] {
                let remoteserver = config.offsiteServer
                let remoteuser = config.offsiteUsername
                if remoteservers.filter({ $0.name == remoteserver }).count == 0 {
                    remoteservers.append(ServerUser(name: remoteserver))
                }
                if remoteusers.filter({ $0.name == remoteuser }).count == 0 {
                    remoteusers.append(ServerUser(name: remoteuser))
                }
            }
        }
    }

    /*
     func setcatalogs() -> Set<String>? {
         if let atpath = nameandpaths?.userHomeDirectoryPath {
             var catalogs = Set<String>()
             do {
                 for folders in try Folder(path: atpath).subfolders {
                     catalogs.insert(folders.name)
                 }
                 return catalogs.filter { $0.isEmpty == false }
             } catch {
                 return nil
             }
         }
         return nil
     }

     func setlocalhome() -> Set<String> {
         var home = Set<String>()
         home.insert(nameandpaths?.userHomeDirectoryPath ?? "")
         return home
     }
     */
    init(configurations: [Configuration]?) {
        Logger.process.info("Assist")
        // nameandpaths = NamesandPaths(.configurations)
        // if let catalogs = setcatalogs() {
        //   self.catalogs = catalogs
        // }
        setserversandlogins(configurations)
    }
}
