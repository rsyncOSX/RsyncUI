//
//  ScheduleRow.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 29/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct ScheduleRowSchedules: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var selecteduuids: Set<UUID>
    var configschedule: ConfigurationSchedule

    var body: some View {
        HStack {
            Spacer()

            selected

            Text(configschedule.schedule)
                .modifier(FixedTag(50, .leading))
            if configschedule.dateStart == "01 Jan 1900 00:00" {
                Text(NSLocalizedString("no startdate", comment: "ScheduleRowSchedules"))
                    .modifier(FixedTag(150, .leading))
            } else {
                Text(localizeddatestart)
                    .modifier(FixedTag(150, .leading))
            }
            if configschedule.dateStop == "01 Jan 2100 00:00" {
                Text(NSLocalizedString("active", comment: "ScheduleRowSchedules"))
                    .modifier(FixedTag(150, .leading))
            } else {
                Text(localizeddatestop)
                    .modifier(FixedTag(150, .leading))
            }
            Text(String(configschedule.logrecords?.count ?? 0))
                .modifier(FixedTag(35, .leading))

            Text(String(activeschedule))

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

    var localizeddatestart: String {
        guard configschedule.dateStart.isEmpty == false else { return "" }
        let usdate = configschedule.dateStart.en_us_date_from_string()
        return usdate.long_localized_string_from_date()
    }

    var localizeddatestop: String {
        if let datestop = configschedule.dateStop {
            guard datestop.isEmpty == false else { return "" }
            let usdate = datestop.en_us_date_from_string()
            return usdate.long_localized_string_from_date()
        }
        return ""
    }

    var activeschedule: Int {
        if let activeschedules = rsyncOSXData.activeschedules {
            let number = activeschedules.filter { $0.hiddenID == configschedule.hiddenID &&
                $0.dateStart?.en_us_string_from_date() == configschedule.dateStart
            }
            return number.count
        }
        return 0
    }
}
