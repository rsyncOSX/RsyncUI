//
//  SchedulesDatePickerView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 05/03/2021.
//

import Foundation
import SwiftUI

enum EnumScheduleDatePicker: String, CaseIterable, Identifiable, CustomStringConvertible {
    case once
    case daily
    case weekly

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

struct SchedulesDatePickerView: View {
    @Binding var selecteddate: Date

    var body: some View {
        DatePicker("", selection: $selecteddate,
                   in: Date()...,
                   displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(GraphicalDatePickerStyle())
            .labelsHidden()
    }
}
