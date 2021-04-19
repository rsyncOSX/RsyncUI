//
//  ConfigurationsSwiftUI.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

struct UniqueserversandLogins: Hashable, Identifiable {
    var id = UUID()
    var offsiteUsername: String?
    var offsiteServer: String?

    init(_ username: String,
         _ servername: String)
    {
        offsiteServer = servername
        offsiteUsername = username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
    }
}

struct ConfigurationsSwiftUI {
    private var configurations: [Configuration]?
    // Initialized during startup
    // private var argumentAllConfigurations: [ArgumentsOneConfiguration]?
    // valid hiddenIDs
    private var validhiddenIDs: Set<Int>?
    // Uniqueue servers and logins
    private var uniqueueserversandlogins: [UniqueserversandLogins]?

    func getuniqueueserversandlogins() -> [UniqueserversandLogins]? {
        return uniqueueserversandlogins
    }

    // Function for getting Configurations read into memory
    func getallconfigurations() -> [Configuration]? {
        return configurations
    }

    func getnumberofconfigurations() -> Int {
        return configurations?.count ?? 0
    }

    // Function for getting Configurations read into memory
    func getconfiguration(hiddenID: Int) -> Configuration? {
        let configuration = configurations?.filter { $0.hiddenID == hiddenID }
        guard configuration?.count == 1 else { return nil }
        return configuration?[0]
    }

    func getvalidhiddenIDs() -> Set<Int>? {
        return validhiddenIDs
    }

    // Function return arguments for rsync, either arguments for
    // real runn or arguments for --dry-run for Configuration at selected index
    func arguments4rsync(hiddenID: Int, argtype: ArgumentsRsync) -> [String] {
        if let config = configurations?.filter({ $0.hiddenID == hiddenID }) {
            guard config.count == 1 else { return [] }
            switch argtype {
            case .arg:
                return ArgumentsSynchronize(config: config[0]).argumentssynchronize(dryRun: false, forDisplay: false) ?? []
            case .argdryRun:
                return ArgumentsSynchronize(config: config[0]).argumentssynchronize(dryRun: true, forDisplay: false) ?? []
            case .argdryRunlocalcataloginfo:
                guard config[0].task != SharedReference.shared.syncremote else { return [] }
                return ArgumentsLocalcatalogInfo(config: config[0]).argumentslocalcataloginfo(dryRun: true, forDisplay: false) ?? []
            }
        }
        return []
    }

    // Function return arguments for rsync, either arguments for
    // real runn or arguments for --dry-run for Configuration at selected index
    func arguments4restore(hiddenID: Int, argtype: ArgumentsRsync) -> [String] {
        if let config = configurations?.filter({ $0.hiddenID == hiddenID }) {
            guard config.count == 1 else { return [] }
            switch argtype {
            case .arg:
                return ArgumentsRestore(config: config[0]).argumentsrestore(dryRun: false, forDisplay: false, tmprestore: false) ?? []
            case .argdryRun:
                return ArgumentsRestore(config: config[0]).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: false) ?? []
            default:
                return []
            }
        }
        return []
    }

    func arguments4tmprestore(hiddenID: Int, argtype: ArgumentsRsync) -> [String] {
        if let config = configurations?.filter({ $0.hiddenID == hiddenID }) {
            guard config.count == 1 else { return [] }
            switch argtype {
            case .arg:
                return ArgumentsRestore(config: config[0]).argumentsrestore(dryRun: false, forDisplay: false, tmprestore: true) ?? []
            case .argdryRun:
                return ArgumentsRestore(config: config[0]).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: true) ?? []
            default:
                return []
            }
        }
        return []
    }

    func arguments4verify(hiddenID: Int) -> [String] {
        if let config = configurations?.filter({ $0.hiddenID == hiddenID }) {
            guard config.count == 1 else { return [] }
            return ArgumentsVerify(config: config[0]).argumentsverify(forDisplay: false) ?? []
        }
        return []
    }

    init(profile: String?) {
        configurations = nil
        let configurationsdata = ReadConfigurationJSON(profile)
        configurations = configurationsdata.configurations
        validhiddenIDs = configurationsdata.validhiddenIDs
        uniqueueserversandlogins = configurationsdata.setuniqueserversandlogins()
        SharedReference.shared.process = nil
    }
}

extension ConfigurationsSwiftUI: Hashable {
    static func == (lhs: ConfigurationsSwiftUI, rhs: ConfigurationsSwiftUI) -> Bool {
        return lhs.configurations == rhs.configurations
    }
}
