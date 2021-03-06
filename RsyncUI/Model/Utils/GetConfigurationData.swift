//
//  GetConfigurationData.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 02/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable cyclomatic_complexity

import Foundation

struct GetConfigurationData {
    private var configurations: [Configuration]?

    func getconfigurationdata(_ hiddenID: Int, resource: ResourceInConfiguration) -> String? {
        if let result = configurations?.filter({ ($0.hiddenID == hiddenID) }) {
            guard result.count > 0 else { return nil }
            switch resource {
            case .localCatalog:
                return result[0].localCatalog
            case .remoteCatalog:
                return result[0].offsiteCatalog
            case .offsiteServer:
                if result[0].offsiteServer.isEmpty {
                    return DictionaryStrings.localhost.rawValue
                } else {
                    return result[0].offsiteServer
                }
            case .task:
                return result[0].task
            case .backupid:
                return result[0].backupID
            case .offsiteusername:
                return result[0].offsiteUsername
            case .sshport:
                if result[0].sshport != nil {
                    return String(result[0].sshport ?? 22)
                } else {
                    return nil
                }
            }
        } else {
            return nil
        }
    }

    init(configurations: [Configuration]?) {
        self.configurations = configurations
    }
}
