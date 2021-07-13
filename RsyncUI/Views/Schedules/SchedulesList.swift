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
                ScheduleRow(selecteduuids: $selecteduuids, configschedule: record)
                    .tag(record)
            }
        }
    }

    var activeschedulesandlogs: [ConfigurationSchedule] {
        if let schedulesandlogs = rsyncUIdata.schedulesandlogs {
            return schedulesandlogs.filter { schedulesandlogs in selectedconfig?.hiddenID == schedulesandlogs.hiddenID
                && schedulesandlogs.schedule != Scheduletype.manuel.rawValue
                && isactive(schedulesandlogs)
            }
        } else {
            return []
        }
    }

    func isactive(_ schedule: ConfigurationSchedule) -> Bool {
        if schedule.schedule == Scheduletype.once.rawValue {
            return schedule.dateStart.en_us_date_from_string() > Date()
        } else {
            return true
        }
    }
}
