//
//  TCPconnections.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class TCPconnections {
    var indexBoolremoteserverOff: [Bool]?
    var client: TCPClient?
    var configurations: [SynchronizeConfiguration]?

    // Test for TCP connection
    func verifyTCPconnection(_ host: String, port: Int, timeout: Int) -> Bool {
        self.client = TCPClient(address: host, port: Int32(port))
        guard let client = client else { return true }
        switch client.connect(timeout: timeout) {
        case .success:
            return true
        default:
            return false
        }
    }

    // Testing all remote servers.
    // Adding connection true or false in array[bool]
    func verifyallremoteserverTCPconnections() {
        indexBoolremoteserverOff = [Bool]()
        guard (configurations?.count ?? 0) > 0 else { return }
        var port = 22
        for i in 0 ..< (configurations?.count ?? 0) {
            if let config = configurations?[i] {
                if config.offsiteServer.isEmpty == false {
                    if let sshport: Int = config.sshport { port = sshport }
                    let success = verifyTCPconnection(config.offsiteServer, port: port, timeout: 1)
                    indexBoolremoteserverOff?.append(success)
                } else {
                    indexBoolremoteserverOff?.append(false)
                }
            }
        }
    }

    init(_ configurations: [SynchronizeConfiguration]?) {
        self.configurations = configurations
    }
}
