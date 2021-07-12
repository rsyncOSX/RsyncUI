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
        HStack {
            Picker("", selection: $selectedscheduletype) {
                ForEach(EnumScheduleDatePicker.allCases) { Text($0.description)
                    .tag($0)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .labelsHidden()

            VStack(alignment: .leading) {
                Text(startdate) + Text("\(selecteddate.localized_string_from_date())")
                    .foregroundColor(Color.blue)
            }
        }
        .frame(width: 300)
        .padding()
    }

    var startdate: String {
        NSLocalizedString("Start", comment: "") + ": "
    }
}
