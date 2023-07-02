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

struct AllConfigurations {
    var configurations: [Configuration]?
    var validhiddenIDs: Set<Int>?

    init(profile: String?) {
        configurations = nil
        let configurationsdata = ReadConfigurationJSON(profile)
        configurations = configurationsdata.configurations
        validhiddenIDs = configurationsdata.validhiddenIDs
        SharedReference.shared.process = nil
    }
}
