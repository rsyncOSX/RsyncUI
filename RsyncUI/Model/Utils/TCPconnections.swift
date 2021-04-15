//
//  TCPconnections.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

class TCPconnections: Delay {
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
    func testAllremoteserverConnections() {
        indexBoolremoteserverOff = nil
        indexBoolremoteserverOff = [Bool]()
        guard (configurations?.getnumberofconfigurations() ?? 0) > 0 else {
            return
        }
        globalBackgroundQueue.async { () -> Void in
            var port: Int = 22
            for i in 0 ..< (self.configurations?.getnumberofconfigurations() ?? 0) {
                if let config = self.configurations?.getallconfigurations()?[i] {
                    if config.offsiteServer.isEmpty == false {
                        if let sshport: Int = config.sshport { port = sshport }
                        let success = self.testTCPconnection(config.offsiteServer, port: port, timeout: 1)
                        if success {
                            self.indexBoolremoteserverOff?.append(false)
                        } else {
                            self.indexBoolremoteserverOff?.append(true)
                        }
                    } else {
                        self.indexBoolremoteserverOff?.append(false)
                    }
                    // Reload table when all remote servers are checked
                    if i == ((self.configurations?.getnumberofconfigurations() ?? 0) - 1) {
                        // Send message to do a refresh table in main view
                        self.connectionscheckcompleted = true
                    }
                }
            }
        }
    }

    init() {}
}
