//
//  ConfigurationsSwiftUI.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

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
