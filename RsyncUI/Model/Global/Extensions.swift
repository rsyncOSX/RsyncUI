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
    func connected(config: Configuration?) -> Bool
    func connected(server: String?) -> Bool
}

extension Connected {
    func connected(config: Configuration?) -> Bool {
        var port = 22
        if let config = config {
            if config.offsiteServer.isEmpty == false {
                if let sshport: Int = config.sshport { port = sshport }
                let success = TCPconnections(nil).verifyTCPconnection(config.offsiteServer, port: port, timeout: 1)
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
                let success = TCPconnections(nil).verifyTCPconnection(server, port: port, timeout: 1)
                return success
            } else {
                return true
            }
        }
        return false
    }
}

// Used to select argument
enum ArgumentsRsync {
    case arg
    case argdryRun
    case argdryRunlocalcataloginfo
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

var globalMainQueue: DispatchQueue {
    return DispatchQueue.main
}

var globalBackgroundQueue: DispatchQueue {
    return DispatchQueue.global(qos: .background)
}

var globalDefaultQueue: DispatchQueue {
    return DispatchQueue.global(qos: .default)
}

// For macOS 12 and 13
extension Binding {
    /// Updates the binding then calls a closure without the new value.
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler()
            }
        )
    }
}
