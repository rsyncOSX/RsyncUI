//
//  TCPconnections.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation
import OSLog

enum Networkerror: LocalizedError {
    case networkdropped
    case noconnection

    var errorDescription: String? {
        switch self {
        case .networkdropped:
            "Network connection is dropped"
        case .noconnection:
            "No connection to server"
        }
    }
}

final class TCPconnections: Sendable {
    func verifyTCPconnection(_ host: String, port: Int, timeout: Int) -> Bool {
        let client = TCPClient(address: host, port: Int32(port))
        switch client.connect(timeout: timeout) {
        case .success:
            return true
        default:
            return false
        }
    }

    // Async Test for TCP connection
    func asyncverifyTCPconnection(_ host: String, port: Int) async throws {
        let client = TCPClient(address: host, port: Int32(port))
        Logger.process.info("TCPconnections: asyncverifyTCPconnection() on main thread \(Thread.isMain)")
        switch client.connect(timeout: 5) {
        case .success:
            return
        default:
            await InterruptProcess()
            throw Networkerror.noconnection
        }
    }
}

extension Thread {
    static var isMain: Bool { isMainThread }
}
