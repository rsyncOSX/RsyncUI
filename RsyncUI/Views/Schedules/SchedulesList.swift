//
//  SchedulesList.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 21/01/2021.
//

import SwiftUI

struct SchedulesList: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var selectedconfig: Configuration?
    @Binding var selectedschedule: ConfigurationSchedule?
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        List(selection: $selectedschedule) {
            ForEach(schedulesandlogs) { record in
                ScheduleRowSchedules(configschedule: record,
                                     selecteduuids: $selecteduuids)
                    .tag(record)
            }
        }
    }

    var schedulesandlogs: [ConfigurationSchedule] {
        if let schedulesandlogs = rsyncOSXData.schedulesandlogs {
            return schedulesandlogs.filter { schedulesandlogs in selectedconfig?.hiddenID == schedulesandlogs.hiddenID }
        } else {
            return []
        }
    }
}
