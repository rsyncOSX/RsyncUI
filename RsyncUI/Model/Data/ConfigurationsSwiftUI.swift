//
//  ConfigurationsSwiftUI.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

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
    private var argumentAllConfigurations: [ArgumentsOneConfiguration]?
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

    func getarguments() -> [ArgumentsOneConfiguration]? {
        return argumentAllConfigurations
    }

    func getvalidhiddenIDs() -> Set<Int>? {
        return validhiddenIDs
    }

    // Function return arguments for rsync, either arguments for
    // real runn or arguments for --dry-run for Configuration at selected index
    func arguments4rsync(hiddenID: Int, argtype: ArgumentsRsync) -> [String] {
        let arguments = argumentAllConfigurations?.filter { $0.hiddenID == hiddenID }
        guard arguments?.count == 1 else { return [] }
        switch argtype {
        case .arg:
            return arguments?[0].arg ?? []
        case .argdryRun:
            return arguments?[0].argdryRun ?? []
        case .argdryRunlocalcataloginfo:
            return arguments?[0].argdryRunLocalcatalogInfo ?? []
        }
    }

    // Function return arguments for rsync, either arguments for
    // real runn or arguments for --dry-run for Configuration at selected index
    func arguments4restore(hiddenID: Int, argtype: ArgumentsRsync) -> [String] {
        let arguments = argumentAllConfigurations?.filter { $0.hiddenID == hiddenID }
        guard arguments?.count == 1 else { return [] }
        switch argtype {
        case .arg:
            return arguments?[0].restore ?? []
        case .argdryRun:
            return arguments?[0].restoredryRun ?? []
        default:
            return []
        }
    }

    func arguments4tmprestore(hiddenID: Int, argtype: ArgumentsRsync) -> [String] {
        let arguments = argumentAllConfigurations?.filter { $0.hiddenID == hiddenID }
        guard arguments?.count == 1 else { return [] }
        switch argtype {
        case .arg:
            return arguments?[0].tmprestore ?? []
        case .argdryRun:
            return arguments?[0].tmprestoredryRun ?? []
        default:
            return []
        }
    }

    func arguments4verify(hiddenID: Int) -> [String] {
        let arguments = argumentAllConfigurations?.filter { $0.hiddenID == hiddenID }
        guard arguments?.count == 1 else { return [] }
        return arguments?[0].verify ?? []
    }

    init(profile: String?) {
        configurations = nil
        let configurationsdata = ConfigurationsData(profile: profile)
        configurations = configurationsdata.configurations
        validhiddenIDs = configurationsdata.validhiddenIDs
        argumentAllConfigurations = configurationsdata.argumentAllConfigurations
        uniqueueserversandlogins = configurationsdata.uniqueserversandlogins
        SharedReference.shared.process = nil
    }
}

extension ConfigurationsSwiftUI: Hashable {
    static func == (lhs: ConfigurationsSwiftUI, rhs: ConfigurationsSwiftUI) -> Bool {
        return lhs.configurations == rhs.configurations
    }
}
