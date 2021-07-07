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
    var connectionscheckcompleted: Bool = false
    var configurations: ConfigurationsSwiftUI?

    // Test for TCP connection
    func testTCPconnection(_ host: String, port: Int, timeout: Int) -> Bool {
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
    func testAllremoteserverConnections() async {
        indexBoolremoteserverOff = [Bool]()
        guard (configurations?.getnumberofconfigurations() ?? 0) > 0 else {
            return
        }
        var port: Int = 22
        for i in 0 ..< (configurations?.getnumberofconfigurations() ?? 0) {
            if let config = configurations?.getallconfigurations()?[i] {
                if config.offsiteServer.isEmpty == false {
                    if let sshport: Int = config.sshport { port = sshport }
                    let success = testTCPconnection(config.offsiteServer, port: port, timeout: 1)
                    if success {
                        indexBoolremoteserverOff?.append(false)
                    } else {
                        indexBoolremoteserverOff?.append(true)
                    }
                } else {
                    indexBoolremoteserverOff?.append(false)
                }
                // Reload table when all remote servers are checked
                if i == ((configurations?.getnumberofconfigurations() ?? 0) - 1) {
                    // Send message to do a refresh table in main view
                    connectionscheckcompleted = true
                }
            }
        }
    }

    init() {}
}
