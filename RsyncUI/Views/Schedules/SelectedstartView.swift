//
//  SelectedstartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//

import SwiftUI

struct SelectedstartView: View {
    @Binding var selecteddate: Date
    @Binding var selectedscheduletype: EnumScheduleDatePicker

    var body: some View {
        VStack(alignment: .leading) {
            Picker("", selection: $selectedscheduletype) {
                ForEach(EnumScheduleDatePicker.allCases) { Text($0.description)
                    .tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
            .labelsHidden()

            Text(startdate) + Text("\(selecteddate.localized_string_from_date())")
                .foregroundColor(Color.blue)
            Text(schedule) + Text("\(selectedscheduletype.rawValue)")
                .foregroundColor(Color.blue)
        }
    }

    var startdate: String {
        NSLocalizedString("Start is", comment: "SchedulesDatePickerView") + ": "
    }

    var schedule: String {
        NSLocalizedString("Schedule is", comment: "SchedulesDatePickerView") + ": "
    }
}
