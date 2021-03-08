//
//  ScheduleRow.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 29/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct ScheduleRowSchedules: View {
    var configschedule: ConfigurationSchedule
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        HStack {
            Spacer()

            selected

            Text(configschedule.schedule)
                .modifier(FixedTag(50, .leading))
            if configschedule.dateStart == "01 Jan 1900 00:00" {
                Text(NSLocalizedString("no startdate", comment: "ScheduleRowSchedules"))
                    .modifier(FixedTag(120, .leading))
            } else {
                Text(configschedule.dateStart)
                    .modifier(FixedTag(120, .leading))
            }
            if configschedule.dateStop == "01 Jan 2100 00:00" {
                Text(NSLocalizedString("no stopdate", comment: "ScheduleRowSchedules"))
                    .modifier(FixedTag(120, .leading))
            } else {
                Text(configschedule.dateStop ?? "")
                    .modifier(FixedTag(120, .leading))
            }
            Text(String(configschedule.logrecords?.count ?? 0))
                .modifier(FixedTag(35, .leading))

            Spacer()
        }
    }

    var selected: some View {
        HStack {
            if selecteduuids.contains(configschedule.id) {
                Text(Image(systemName: "arrowtriangle.right.fill"))
                    .foregroundColor(.green)
                    .frame(width: 20, alignment: .leading)
            } else {
                Text("")
                    .frame(width: 20, alignment: .leading)
            }
        }
    }
}
