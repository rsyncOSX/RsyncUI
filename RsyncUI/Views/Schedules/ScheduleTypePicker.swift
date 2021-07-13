//
//  SelectedstartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//

import SwiftUI

struct ScheduleTypePicker: View {
    @Binding var selecteddate: Date
    @Binding var selectedscheduletype: EnumScheduleTypePicker

    var body: some View {
        HStack {
            Picker("", selection: $selectedscheduletype) {
                ForEach(EnumScheduleTypePicker.allCases) { Text($0.description)
                    .tag($0)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .labelsHidden()
        }
        .padding()
    }
}
