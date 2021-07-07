//
//  TCPconnections.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

class TCPconnections {
    private var indexBoolremoteserverOff: [Bool]?
    var client: TCPClient?
    var configurations: [Configuration]?

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

    // Getting the structure for test connection
    func gettestAllremoteserverConnections() -> [Bool]? {
        return indexBoolremoteserverOff
    }

    // Testing all remote servers.
    // Adding connection true or false in array[bool]
    // Do the check in background que, reload table in global main queue
    func verifyallremoteserverTCPconnections() async {
        indexBoolremoteserverOff = [Bool]()
        guard (configurations?.count ?? 0) > 0 else { return }
        var port: Int = 22
        for i in 0 ..< (configurations?.count ?? 0) {
            if let config = configurations?[i] {
                if config.offsiteServer.isEmpty == false {
                    if let sshport: Int = config.sshport { port = sshport }
                    let success = verifyTCPconnection(config.offsiteServer, port: port, timeout: 1)
                    if success {
                        indexBoolremoteserverOff?.append(false)
                    } else {
                        indexBoolremoteserverOff?.append(true)
                    }
                } else {
                    indexBoolremoteserverOff?.append(false)
                }
            }
        }
        print("TCP test done")
    }

    init(_ configurations: [Configuration]?) {
        self.configurations = configurations
    }
}
