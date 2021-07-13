//
//  SelectedstartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//

import SwiftUI

struct ScheduleTypePicker: View {
    @Binding var selecteddate: Date
    @Binding var selectedscheduletype: EnumScheduleDatePicker

    var body: some View {
        HStack {
            Picker("", selection: $selectedscheduletype) {
                ForEach(EnumScheduleDatePicker.allCases) { Text($0.description)
                    .tag($0)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .labelsHidden()
        }
        .frame(width: 200)
        .padding()
    }
}
