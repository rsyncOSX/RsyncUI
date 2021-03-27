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
                    .modifier(FixedTag(130, .leading))
            } else {
                Text(localizeddatestart)
                    .modifier(FixedTag(130, .leading))
            }
            if configschedule.dateStop == "01 Jan 2100 00:00" {
                Text(NSLocalizedString("active", comment: "ScheduleRowSchedules"))
                    .modifier(FixedTag(130, .leading))
            } else {
                Text(localizeddatestop)
                    .modifier(FixedTag(130, .leading))
            }
            Text(String(configschedule.logrecords?.count ?? 0))
                .modifier(FixedTag(35, .trailing))

            Text(activeschedule)
                .modifier(FixedTag(35, .trailing))
                .foregroundColor(Color.blue)

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

    var activeschedule: String {
        if let activeschedules =
            ScheduleSortedAndExpand(profile: rsyncOSXData.profile,
                                    scheduleConfigurations: rsyncOSXData.schedulesandlogs).sortedexpandedeschedules
        {
            let number = activeschedules.filter { $0.hiddenID == configschedule.hiddenID &&
                $0.dateStart?.en_us_string_from_date() == configschedule.dateStart
            }
            guard number.count == 1 else { return "" }
            return timestring(number[0].timetostart ?? 0)
        }
        return ""
    }
}

extension ScheduleRowSchedules {
    // Calculation of time to a spesific date
    func timestring(_ seconds: Double) -> String {
        var result: String?
        let (hr, minf) = modf(seconds / 3600)
        let (min, secf) = modf(60 * minf)
        // hr, min, 60 * secf
        if hr == 0, min == 0 {
            if secf < 0.9 {
                result = String(format: "%.0f", 60 * secf) + "s"
            } else {
                result = String(format: "%.0f", 1.0) + "m"
            }
        } else if hr == 0, min < 60 {
            if secf < 0.9 {
                result = String(format: "%.0f", min) + "m"
            } else {
                result = String(format: "%.0f", min + 1) + "m"
            }
        } else if hr < 25 {
            result = String(format: "%.0f", hr) + NSLocalizedString("h", comment: "datetime") + " "
                + String(format: "%.0f", min) + "m"
        } else {
            result = String(format: "%.0f", hr / 24) + "d"
        }
        return result ?? ""
    }
}
