//
//  TCPconnections.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24.08.2018.
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
