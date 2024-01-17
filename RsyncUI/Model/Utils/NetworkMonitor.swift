//
//  NetworkMonitor.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/06/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation
import Network

enum Networkerror: LocalizedError {
    case networkdropped

    var errorDescription: String? {
        switch self {
        case .networkdropped:
            return "Network connection is dropped"
        }
    }
}

final class NetworkMonitor {
    var monitor: NWPathMonitor?
    var netStatusChangeHandler: (() -> Void)?

    var isConnected: Bool {
        guard let monitor = monitor else { return false }
        return monitor.currentPath.status == .satisfied
    }

    var interfaceType: NWInterface.InterfaceType? {
        guard let monitor = monitor else { return nil }
        return monitor.currentPath.availableInterfaces.filter {
            monitor.currentPath.usesInterfaceType($0.type)
        }
        .first?.type
    }

    var availableInterfacesTypes: [NWInterface.InterfaceType]? {
        guard let monitor = monitor else { return nil }
        return monitor.currentPath.availableInterfaces.map { $0.type }
    }

    var isExpensive: Bool {
        return monitor?.currentPath.isExpensive ?? false
    }

    init() {
        startMonitoring()
    }

    deinit {
        self.stopMonitoring()
    }

    func startMonitoring() {
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetStatus_Monitor")
        monitor?.start(queue: queue)
        monitor?.pathUpdateHandler = { _ in
            self.netStatusChangeHandler?()
        }
    }

    func stopMonitoring() {
        if let monitor = monitor {
            monitor.cancel()
            self.monitor = nil
        }
    }
}
