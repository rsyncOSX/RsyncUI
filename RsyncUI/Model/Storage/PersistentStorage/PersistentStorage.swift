//
//  PersistantStorage.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/11/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation

final class PersistentStorage {
    var configJSON: WriteConfigurationJSON?
    var scheduleJSON: WriteScheduleJSON?
    var whattoreadorwrite: WhatToReadWrite?

    var configurations: [Configuration]?
    var schedules: [ConfigurationSchedule]?

    func convert(profile: String?) {
        if let profile = profile {
            _ = WriteConfigurationJSON(profile: profile,
                                       configurations: configurations)
            _ = WriteScheduleJSON(profile: profile,
                                  schedules: schedules)
        } else {
            _ = WriteConfigurationJSON(profile: nil,
                                       configurations: configurations)
            _ = WriteScheduleJSON(profile: nil,
                                  schedules: schedules)
        }
    }

    func saveMemoryToPersistentStore() {
        switch whattoreadorwrite {
        case .configuration:
            configJSON?.saveconfigInMemoryToPersistentStore()
        case .schedule:
            scheduleJSON?.savescheduleInMemoryToPersistentStore()
        default:
            return
        }
    }

    init(profile: String?,
         whattoreadorwrite: WhatToReadWrite,
         configurations: [Configuration]?,
         schedules: [ConfigurationSchedule]?)
    {
        self.whattoreadorwrite = whattoreadorwrite
        self.configurations = configurations
        self.schedules = schedules

        switch whattoreadorwrite {
        case .configuration:
            configJSON = WriteConfigurationJSON(profile: profile,
                                                configurations: self.configurations)
        case .schedule:
            scheduleJSON = WriteScheduleJSON(profile: profile,
                                             schedules: self.schedules)
        default:
            return
        }
    }

    deinit {
        // print("deinit PersistentStorage")
        // print(self.whattoreadorwrite)
        self.configJSON = nil
        self.scheduleJSON = nil
    }
}
