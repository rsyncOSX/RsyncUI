//
//  TCPconnections.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation
import OSLog

struct TCPconnections: Sendable {
    func verifyTCPconnection(_ host: String, port: Int, timeout: Int) -> Bool {
        let client = TCPClient(address: host, port: Int32(port))
        switch client.connect(timeout: timeout) {
        case .success:
            return true
        default:
            return false
        }
    }
}

/*
 // Async Test for TCP connection
 nonisolated func asyncverifyTCPconnection(_ host: String, port: Int) async throws {
     let client = TCPClient(address: host, port: Int32(port))
     Logger.process.debugtthreadonly("TCPconnections: asyncverifyTCPconnection()")
     switch client.connect(timeout: 5) {
     case .success:
         return
     default:
         await InterruptProcess()
     }
 }
 */
