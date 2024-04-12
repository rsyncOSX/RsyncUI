//
//  Extensions.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation
import SwiftUI

extension Sequence {
    func sorted<T: Comparable>(
        by keyPath: KeyPath<Element, T>,
        using comparator: (T, T) -> Bool = (<)
    ) -> [Element] {
        sorted { a, b in
            comparator(a[keyPath: keyPath], b[keyPath: keyPath])
        }
    }
}

protocol Connected {
    func connected(config: SynchronizeConfiguration?) -> Bool
    func connected(server: String?) -> Bool
}

extension Connected {
    func connected(config: SynchronizeConfiguration?) -> Bool {
        var port = 22
        if let config = config {
            if config.offsiteServer.isEmpty == false {
                if let sshport: Int = config.sshport { port = sshport }
                let tcpconnection = TCPconnections()
                let success = tcpconnection.verifyTCPconnection(config.offsiteServer, port: port, timeout: 1)
                return success
            } else {
                return true
            }
        }
        return false
    }

    func connected(server: String?) -> Bool {
        if let server = server {
            let port = 22
            if server.isEmpty == false {
                let tcpconnection = TCPconnections()
                let success = tcpconnection.verifyTCPconnection(server, port: port, timeout: 1)
                return success
            } else {
                return true
            }
        }
        return false
    }
}

// Enum which resource to return
enum ResourceInConfiguration {
    case remoteCatalog
    case localCatalog
    case offsiteServer
    case task
    case backupid
    case offsiteusername
    case sshport
}
