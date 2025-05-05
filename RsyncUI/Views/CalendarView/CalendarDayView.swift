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
    @Bindable var futuredates: ObservableFutureSchedules
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
                        dateRun = date.en_string_from_date()
                        dateAdded = Date.now.en_string_from_date()
                        istappeddayint = day.dayInt
                    }
                }
                .contextMenu {
                    ForEach(Array(futuredates.futureschedules), id: \.self) { schedule in
                        if istoday(runDate: schedule.dateRun, day: day) {
                            VStack {
                                Text(schedule.profile ?? "")
                                Text(schedule.dateRun ?? "")
                            }
                        }
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
                        dateRun = date.en_string_from_date()
                        dateAdded = Date.now.en_string_from_date()
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
                                ? todaycolor.opacity(0.3)
                                : defaultcolor.opacity(0.3)
                        )
                )
                .onTapGesture {
                    if let date = settappeddate(day) {
                        dateRun = date.en_string_from_date()
                        dateAdded = Date.now.en_string_from_date()
                        istappeddayint = day.dayInt
                    }
                }
                .contextMenu {
                    ForEach(Array(futuredates.futureschedules), id: \.self) { schedule in
                        if istoday(runDate: schedule.dateRun, day: day) {
                            VStack {
                                Text(schedule.profile ?? "")
                                Text(schedule.dateRun ?? "")
                            }
                        }
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

    func istoday(runDate: String?, day: Date) -> Bool {
        if let runDate {
            let run = runDate.en_date_from_string()
            var rundatecomponents = DateComponents()
            rundatecomponents.day = run.dayInt
            rundatecomponents.year = run.yearInt
            rundatecomponents.month = run.monthInt

            var daydatecomponents = DateComponents()
            daydatecomponents.day = day.dayInt
            daydatecomponents.year = day.yearInt
            daydatecomponents.month = day.monthInt

            let calendar = Calendar.current

            if let calendarrun = calendar.date(from: rundatecomponents), let calendarday = calendar.date(from: daydatecomponents) {
                return calendarrun == calendarday
            }
            return false
        }
        return false
    }
}
