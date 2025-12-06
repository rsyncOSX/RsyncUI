//
//  extension Date
//  RsyncOSX
//
//  Created by Thomas Evensen on 08/12/2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

extension Date {
    func daymonth() -> Int {
        let calendar = Calendar.current
        let dateComponent = (calendar as NSCalendar).components(.day, from: self)
        return dateComponent.day ?? 1
    }

    func getWeekday() -> Int {
        let calendar = Calendar.current
        return (calendar as NSCalendar).components(.weekday, from: self).weekday ?? 1
    }

    func isSelectedDayofWeek(day: NumDayofweek) -> Bool {
        getWeekday() == day.rawValue
    }

    static func > (lhs: Date, rhs: Date) -> Bool {
        rhs.compare(lhs) == ComparisonResult.orderedAscending
    }

    var ispreviousmonth: Bool {
        let calendar = Calendar.current
        let yearComponent = (calendar as NSCalendar).components(.year, from: self)
        let monthComponent = (calendar as NSCalendar).components(.month, from: self)
        let today = Date()
        let todayComponentyear = (calendar as NSCalendar).components(.year, from: today)
        let todaymonthComponent = (calendar as NSCalendar).components(.month, from: today)
        if yearComponent == todayComponentyear {
            if let selected = monthComponent.month, let today = todaymonthComponent.month {
                if selected == today - 1 {
                    return true
                }
            }
        }
        return false
    }

    var isnexttwomonths: Bool {
        let calendar = Calendar.current
        let yearComponent = (calendar as NSCalendar).components(.year, from: self)
        let monthComponent = (calendar as NSCalendar).components(.month, from: self)
        let today = Date()
        let todayComponentyear = (calendar as NSCalendar).components(.year, from: today)
        let todaymonthComponent = (calendar as NSCalendar).components(.month, from: today)
        if yearComponent == todayComponentyear {
            if let selected = monthComponent.month, let today = todaymonthComponent.month {
                if selected <= today + 1 {
                    return true
                }
            }
        }
        return false
    }

    func localized_string_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        return dateformatter.string(from: self)
    }

    func long_localized_string_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .long
        return dateformatter.string(from: self)
    }

    func en_string_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter.string(from: self)
    }

    func en_string_month_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy"
        return dateformatter.string(from: self)
    }

    func en_string_hour_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "HH:mm"
        return dateformatter.string(from: self)
    }

    func shortlocalized_string_from_date() -> String {
        // MM-dd-yyyy HH:mm
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "MM-dd-yyyy:HH:mm"
        return dateformatter.string(from: self)
    }

    func localized_weekday_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "EEEE"
        return dateformatter.string(from: self)
    }

    func localized_month_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "MMMM"
        return dateformatter.string(from: self)
    }

    static let firstDayOfWeek = Calendar.current.firstWeekday

    static var capitalizedFirstLettersOfWeekdays: [String] {
        let calendar = Calendar.current
        // Adjusted for the different weekday starts
        var weekdays = calendar.shortWeekdaySymbols
        if firstDayOfWeek > 1 {
            for _ in 1 ..< firstDayOfWeek {
                if let first = weekdays.first {
                    weekdays.append(first)
                    weekdays.removeFirst()
                }
            }
        }
        return weekdays.map(\.capitalized)
    }

    static var fullMonthNames: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current

        return (1 ... 12).compactMap { month in
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMM")
            let date = Calendar.current.date(from: DateComponents(year: 2000, month: month, day: 1))
            return date.map { dateFormatter.string(from: $0) }
        }
    }

    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    var endOfCurrentMonth: Date {
        guard let interval = Calendar.current.dateInterval(of: .month, for: self),
              let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: interval.end)
        else {
            return self
        }
        return lastDay
    }

    var endOfNextMonth: Date? {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: self),
              let interval = Calendar.current.dateInterval(of: .month, for: nextMonth),
              let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: interval.end)
        else {
            return nil
        }
        return lastDay
    }

    var numberOfDaysInMonth: Int {
        Calendar.current.component(.day, from: endOfCurrentMonth)
    }

    // Fix: negative days causing issue for first row
    var firstWeekDayBeforeStart: Date {
        let startOfMonthWeekday = Calendar.current.component(.weekday, from: startOfMonth)
        var numberFromPreviousMonth = startOfMonthWeekday - Self.firstDayOfWeek
        if numberFromPreviousMonth < 0 {
            numberFromPreviousMonth += 7 // Adjust to a 0-6 range if negative
        }
        guard let adjusted = Calendar.current.date(byAdding: .day, value: -numberFromPreviousMonth, to: startOfMonth) else {
            return startOfMonth
        }
        return adjusted
    }

    var calendarDisplayDays: [Date] {
        var days: [Date] = []
        // Start with days from the previous month to fill the grid
        let firstDisplayDay = firstWeekDayBeforeStart
        var day = firstDisplayDay
        while day < startOfMonth {
            days.append(day)
            guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        // Add days of the current month
        for dayOffset in 0 ..< numberOfDaysInMonth {
            let newDay = Calendar.current.date(byAdding: .day, value: dayOffset, to: startOfMonth)
            if let newDay {
                days.append(newDay)
            }
        }
        return days
    }

    var yearInt: Int {
        Calendar.current.component(.year, from: self)
    }

    var monthInt: Int {
        Calendar.current.component(.month, from: self)
    }

    var dayInt: Int {
        Calendar.current.component(.day, from: self)
    }

    var hourInt: Int {
        Calendar.current.component(.hour, from: self)
    }

    var minuteInt: Int {
        Calendar.current.component(.minute, from: self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

extension String {
    func en_date_from_string() -> Date {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter.date(from: self) ?? Date()
    }

    func validate_en_date_from_string() -> Date? {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter.date(from: self)
    }

    func localized_date_from_string() -> Date {
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        return dateformatter.date(from: self) ?? Date()
    }
}

extension Double {
    func latest() -> String {
        let seconds = self

        // Less than 1 minute (60 seconds)
        if seconds < 60 {
            let secondsValue = Int(seconds)
            return secondsValue == 1 ? "\(secondsValue) second" : "\(secondsValue) seconds"
        }
        // Less than 1 hour (3600 seconds)
        else if seconds < 3600 {
            let minutes = seconds / 60
            return minutes < 2 ? String(format: "%.0f min", minutes) : String(format: "%.0f mins", minutes)
        }
        // Less than 1 day (86400 seconds)
        else if seconds < 86400 {
            let hours = seconds / 3600
            return hours < 2 ? String(format: "%.1f hour", hours) : String(format: "%.1f hours", hours)
        }
        // 1 day or more
        else {
            let days = seconds / 86400
            return days < 2 ? String(format: "%.1f day", days) : String(format: "%.1f days", days)
        }
    }
}
