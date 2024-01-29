//
//  UserServer.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/12/2022.
//

import Foundation

@Observable
final class UserServer {
    @ObservationIgnored
    var remoteservers = Set<String>()
    @ObservationIgnored
    var remoteusers = Set<String>()

    func setserversandlogins(_ configurations: [SynchronizeConfiguration]?) {
        guard configurations != nil else { return }
        for i in 0 ..< (configurations?.count ?? 0) {
            if let config = configurations?[i] {
                let remoteserver = config.offsiteServer
                let remoteuser = config.offsiteUsername
                if remoteservers.filter({ $0 == remoteserver }).count == 0 {
                    remoteservers.insert(remoteserver)
                }
                if remoteusers.filter({ $0 == remoteuser }).count == 0 {
                    remoteusers.insert(remoteuser)
                }
            }
        }
    }

    init(configurations: [SynchronizeConfiguration]?) {
        setserversandlogins(configurations)
    }
}
