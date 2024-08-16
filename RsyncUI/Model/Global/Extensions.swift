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
    @MainActor func connected(server: String?) -> Bool
}

@MainActor
extension Connected {
    func connected(server: String?) -> Bool {
        if let server {
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

protocol PropogateError {
    @MainActor func propogateerror(error: Error)
}

@MainActor
extension PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}
