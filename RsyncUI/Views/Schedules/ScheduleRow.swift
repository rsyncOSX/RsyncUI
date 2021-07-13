//
//  ScheduleRow.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 29/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
import SwiftUI

struct ScheduleRow: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selecteduuids: Set<UUID>
    var configschedule: ConfigurationSchedule

    var body: some View {
        HStack {
            selected

            Text(configschedule.schedule)
                .modifier(FixedTag(50, .trailing))
            Text(localizeddatestart)
                .modifier(FixedTag(200, .leading))
            Text("active")
                .modifier(FixedTag(50, .leading))
                .foregroundColor(Color.green)
            Text(activeschedule)
                .modifier(FixedTag(80, .trailing))
                .foregroundColor(Color.green)
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
            ScheduleSortedAndExpand(profile: rsyncUIdata.profile,
                                    scheduleConfigurations: rsyncUIdata.schedulesandlogs).sortedexpandedeschedules
        {
            let number = activeschedules.filter { $0.hiddenID == configschedule.hiddenID &&
                $0.dateStart?.en_us_string_from_date() == configschedule.dateStart &&
                $0.schedule == configschedule.schedule
            }
            guard number.count == 1 else { return "" }
            return timestring(number[0].timetostart ?? 0)
        }
        return ""
    }
}

extension ScheduleRow {
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
            result = String(format: "%.0f", hr) + "h" + " "
                + String(format: "%.0f", min) + "m"
        } else {
            result = String(format: "%.0f", hr / 24) + "d"
        }
        return result ?? ""
    }
}
