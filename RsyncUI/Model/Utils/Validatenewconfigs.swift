//
//  Validatenewconfigs.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 08/01/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity

import Foundation

struct Validatenewconfigs: Connected {
    var validated: Bool = false

    init(config: SynchronizeConfiguration) {
        guard config.localCatalog.isEmpty == false, config.offsiteCatalog.isEmpty == false else { return }
        guard config.localCatalog != "/" || config.offsiteCatalog != "/" else { return }

        if config.offsiteServer.isEmpty == false {
            guard config.offsiteUsername.isEmpty == false else { return }
        }
        if config.offsiteUsername.isEmpty == false {
            guard config.offsiteServer.isEmpty == false else { return }
        }
        if config.task == SharedReference.shared.snapshot {
            guard config.snapshotnum == 1 else { return }
            // also check if connected because creating base remote catalog if remote server
            // must be connected to create remote base catalog
            guard connected(server: config.offsiteServer) else { return }
        }
        if config.task == SharedReference.shared.syncremote {
            guard config.offsiteServer.isEmpty == false, config.offsiteUsername.isEmpty == false else { return }
        }
        validated = true
    }

    init(config: SynchronizeConfiguration, Edit _: Bool) {
        guard config.localCatalog.isEmpty == false, config.offsiteCatalog.isEmpty == false else { return }
        guard config.localCatalog != "/" || config.offsiteCatalog != "/" else { return }
        if config.offsiteServer.isEmpty == false {
            guard config.offsiteUsername.isEmpty == false else { return }
        }
        if config.offsiteUsername.isEmpty == false {
            guard config.offsiteServer.isEmpty == false else { return }
        }
        validated = true
    }
}

// swiftlint:enable cyclomatic_complexity
