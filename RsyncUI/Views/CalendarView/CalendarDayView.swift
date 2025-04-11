//
//  CalendarDayView.swift
//  Calendar
//
//  Created by Thomas Evensen on 11/04/2025.
//

import Foundation
import SwiftUI

enum ForegroundStyle {
    case thereisaschedule
    case istappednoschedule
    case normalday
}

struct CalendarDayView: View {
   
    @Binding var dateRun: String
    @Binding var dateAdded: String
    @Binding var istappeddayint: Int

    let defaultcolor: Color = .blue
    let schedulecolor: Color = .yellow
    let istappedecolor: Color = .green
    let todaycolor: Color = .red

    var day: Date
    var style: ForegroundStyle

    var body: some View {
        switch style {
        case .thereisaschedule:
            Text(day.formatted(.dateTime.day()))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Circle()
                        .foregroundStyle(
                            istappeddayint == day.dayInt ?
                                istappedecolor.opacity(0.3) : schedulecolor.opacity(0.3)
                        )
                )
                .onTapGesture {
                    if let date = settappeddate(day) {
                        dateRun = date.en_us_string_from_date()
                        dateAdded = Date.now.en_us_string_from_date()
                        istappeddayint = day.dayInt
                    }
                }
        case .istappednoschedule:
            Text(day.formatted(.dateTime.day()))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Circle()
                        .foregroundStyle(
                            istappedecolor.opacity(0.3)
                        )
                )
                .onTapGesture {
                    if let date = settappeddate(day) {
                        dateRun = date.en_us_string_from_date()
                        dateAdded = Date.now.en_us_string_from_date()
                        istappeddayint = day.dayInt
                    }
                }
        case .normalday:
            Text(day.formatted(.dateTime.day()))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Circle()
                        .foregroundStyle(
                            Date.now.startOfDay == day.startOfDay
                                ? .red.opacity(0.3)
                                : defaultcolor.opacity(0.3)
                        )
                )
                .onTapGesture {
                    if let date = settappeddate(day) {
                        dateRun = date.en_us_string_from_date()
                        dateAdded = Date.now.en_us_string_from_date()
                        istappeddayint = day.dayInt
                    }
                }
        }
    }

    func settappeddate(_ date: Date) -> Date? {
        var datecomponents = DateComponents()
        datecomponents.hour = 8
        datecomponents.day = date.dayInt
        datecomponents.year = date.yearInt
        datecomponents.month = date.monthInt
        let calendar = Calendar.current
        return calendar.date(from: datecomponents)
    }
}
