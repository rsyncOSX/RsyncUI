//
//  TableofNotExeSchedules.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/10/2025.
//

import SwiftUI

struct TableofNotExeSchedules: View {
    @Binding var selecteduuids: Set<ScheduledItem.ID>
    
    var body: some View {
        Table(GlobalTimer.shared.notExecutedSchedulesafterWakeUp, selection: $selecteduuids) {
            TableColumn("Profile") { data in
                Text(data.scheduledata?.profile ?? "Default")
            }
            .width(min: 100, max: 150)

            TableColumn("Schedule") { data in
                Text(data.scheduledata?.schedule ?? "")
            }
            .width(min: 50, max: 70)

            TableColumn("Run") { data in
                Text(data.scheduledata?.dateRun ?? "")
            }
            .width(max: 120)

            TableColumn("Added") { data in
                Text(data.scheduledata?.dateAdded ?? "")
            }
            .width(max: 120)
            
            TableColumn("Min/hour/day") { data in
                var seconds: Double {
                    if let date = data.scheduledata?.dateRun {
                        let lastbackup = date.en_date_from_string()
                        return lastbackup.timeIntervalSinceNow
                    } else {
                        return 0
                    }
                }

                Text(seconds.latest())
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 90)
        }
    }
}
