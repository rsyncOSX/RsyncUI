//
//  SchedulesList.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 21/01/2021.
//

import SwiftUI

struct SchedulesList: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selectedconfig: Configuration?
    @Binding var selectedschedule: ConfigurationSchedule?
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        List(selection: $selectedschedule) {
            ForEach(activeschedulesandlogs) { record in
                ScheduleRowSchedules(selecteduuids: $selecteduuids, configschedule: record)
                    .tag(record)
            }
            .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
        }
    }

    var activeschedulesandlogs: [ConfigurationSchedule] {
        if let schedulesandlogs = rsyncUIdata.schedulesandlogs {
            return schedulesandlogs.filter { schedulesandlogs in selectedconfig?.hiddenID == schedulesandlogs.hiddenID
                && schedulesandlogs.dateStop == "01 Jan 2100 00:00"
            }
        } else {
            return []
        }
    }
}
