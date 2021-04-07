//
//  SchedulesList.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 21/01/2021.
//

import SwiftUI

struct SchedulesList: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var selectedconfig: Configuration?
    @Binding var selectedschedule: ConfigurationSchedule?
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        List(selection: $selectedschedule) {
            ForEach(schedulesandlogs) { record in
                ScheduleRowSchedules(selecteduuids: $selecteduuids, configschedule: record)
                    .tag(record)
            }
            .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
        }
    }

    var schedulesandlogs: [ConfigurationSchedule] {
        if let schedulesandlogs = rsyncUIData.schedulesandlogs {
            return schedulesandlogs.filter { schedulesandlogs in selectedconfig?.hiddenID == schedulesandlogs.hiddenID }
        } else {
            return []
        }
    }
}
