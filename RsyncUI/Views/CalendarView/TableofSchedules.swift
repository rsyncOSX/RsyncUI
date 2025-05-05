//
//  TableofSchedules.swift
//  Calendar
//
//  Created by Thomas Evensen on 25/03/2025.
//

import SwiftUI

struct TableofSchedules: View {
    @Binding var selecteduuids: Set<SchedulesConfigurations.ID>
    let schedules: [SchedulesConfigurations]

    var body: some View {
        Table(schedules, selection: $selecteduuids) {
            TableColumn("Profile") { data in
                Text(data.profile ?? SharedConstants().defaultprofile)
            }
            .width(min: 100, max: 150)

            TableColumn("Schedule") { data in
                Text(data.schedule ?? "")
            }
            .width(min: 50, max: 70)

            TableColumn("Run") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)

            TableColumn("Added") { data in
                Text(data.dateAdded ?? "")
            }
            .width(max: 120)
        }
    }
}
