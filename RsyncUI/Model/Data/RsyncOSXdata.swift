//
//  RsyncOSXdata.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct Readdatafromstore {
    var profile: String?
    var configurationData: ConfigurationsSwiftUI
    var validhiddenIDs: Set<Int>
    var scheduleData: SchedulesSwiftUI

    init(profile: String?) {
        self.profile = profile
        configurationData = ConfigurationsSwiftUI(profile: self.profile)
        validhiddenIDs = configurationData.getvalidhiddenIDs() ?? Set()
        scheduleData = SchedulesSwiftUI(profile: self.profile, validhiddenIDs: validhiddenIDs)
    }
}

final class RsyncOSXdata: ObservableObject {
    @Published var rsyncdata: Readdatafromstore?
    @Published var configurations: [Configuration]?
    @Published var schedulesandlogs: [ConfigurationSchedule]?
    @Published var arguments: [ArgumentsOneConfiguration]?
    @Published var profile: String?
    @Published var alllogssorted: [Log]?
    @Published var activeschedules: [ActiveSchedules]?

    func update() {
        objectWillChange.send()
    }

    init(profile: String?) {
        self.profile = profile
        if profile == NSLocalizedString("Default profile", comment: "default profile") || profile == nil {
            rsyncdata = Readdatafromstore(profile: nil)
        } else {
            rsyncdata = Readdatafromstore(profile: profile)
        }
        configurations = rsyncdata?.configurationData.getallconfigurations()
        schedulesandlogs = rsyncdata?.scheduleData.getschedules()
        arguments = rsyncdata?.configurationData.getarguments()
        alllogssorted = rsyncdata?.scheduleData.getalllogs()
        if profile == NSLocalizedString("Default profile", comment: "default profile") || profile == nil {
            activeschedules = ScheduleSortedAndExpand(profile: nil, scheduleConfigurations: schedulesandlogs).sortedexpandedeschedules
        } else {
            activeschedules = ScheduleSortedAndExpand(profile: profile, scheduleConfigurations: schedulesandlogs).sortedexpandedeschedules
        }

        objectWillChange.send()
    }
}
