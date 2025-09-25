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

    var ispreviousmont: Bool {
        let calendar = Calendar.current
        let yearComponent = (calendar as NSCalendar).components(.year, from: self)
        let monthComponent = (calendar as NSCalendar).components(.month, from: self)
        let today = Date()
        let todayComponentyear = (calendar as NSCalendar).components(.year, from: today)
        let todaymonthComponent = (calendar as NSCalendar).components(.month, from: today)
        if yearComponent == todayComponentyear {
            if (monthComponent.month ?? -1) == (todaymonthComponent.month ?? -1) - 1 {
                return true
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
        Calendar.current.dateInterval(of: .month, for: self)!.start
    }

    var endOfMonth: Date {
        let lastDay = Calendar.current.dateInterval(of: .month, for: self)!.end
        return Calendar.current.date(byAdding: .day, value: -1, to: lastDay)!
    }

    /*
     var startOfPreviousMonth: Date {
         let dayInPreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: self)!
         return dayInPreviousMonth.startOfMonth
     }
     */
    var numberOfDaysInMonth: Int {
        Calendar.current.component(.day, from: endOfMonth)
    }

    // Fix: negative days causing issue for first row
    var firstWeekDayBeforeStart: Date {
        let startOfMonthWeekday = Calendar.current.component(.weekday, from: startOfMonth)
        var numberFromPreviousMonth = startOfMonthWeekday - Self.firstDayOfWeek
        if numberFromPreviousMonth < 0 {
            numberFromPreviousMonth += 7 // Adjust to a 0-6 range if negative
        }
        return Calendar.current.date(byAdding: .day, value: -numberFromPreviousMonth, to: startOfMonth)!
    }

    var calendarDisplayDays: [Date] {
        var days: [Date] = []
        // Start with days from the previous month to fill the grid
        let firstDisplayDay = firstWeekDayBeforeStart
        var day = firstDisplayDay
        while day < startOfMonth {
            days.append(day)
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        }
        // Add days of the current month
        for dayOffset in 0 ..< numberOfDaysInMonth {
            let newDay = Calendar.current.date(byAdding: .day, value: dayOffset, to: startOfMonth)
            days.append(newDay!)
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

/*

 func monthNameShort() -> String {
     let dateFormatter = DateFormatter()
     dateFormatter.dateFormat = "MMM"
     return dateFormatter.string(from: self)
 }

 func dayNameShort() -> String {
     let dateFormatter = DateFormatter()
     dateFormatter.dateFormat = "EEEE"
     return dateFormatter.string(from: self)
 }

 func monthNameFull() -> String {
     let dateFormatter = DateFormatter()
     dateFormatter.dateFormat = "MMMM YYYY"
     return dateFormatter.string(from: self)
 }

 func isSaturday() -> Bool {
     return getWeekday() == 7
 }

 func isSunday() -> Bool {
     return getWeekday() == 1
 }

 func isWeekday() -> Bool {
     return getWeekday() != 1
 }

 func dateByAddingMonths(_ months: Int) -> Date {
     let calendar = Calendar.current
     var dateComponent = DateComponents()
     dateComponent.month = months
     return (calendar as NSCalendar).date(byAdding: dateComponent, to: self, options: NSCalendar.Options.matchNextTime)!
 }

 func dateByAddingDays(_ days: Int) -> Date {
     let calendar = Calendar.current
     var dateComponent = DateComponents()
     dateComponent.day = days
     return (calendar as NSCalendar).date(byAdding: dateComponent, to: self, options: NSCalendar.Options.matchNextTime)!
 }

 func weekday() -> Int? {
     let calendar = Calendar.current
     let dateComponent = (calendar as NSCalendar).components(.weekday, from: self)
     return dateComponent.weekday
 }

 func numberOfDaysInMonth() -> Int {
     let calendar = Calendar.current
     let days = (calendar as NSCalendar).range(of: NSCalendar.Unit.day, in: NSCalendar.Unit.month, for: self)
     return days.length
 }
 func month() -> Int? {
     let calendar = Calendar.current
     let dateComponent = (calendar as NSCalendar).components(.month, from: self)
     return dateComponent.month
 }

 func year() -> Int? {
     let calendar = Calendar.current
     let dateComponent = (calendar as NSCalendar).components(.year, from: self)
     return dateComponent.year
 }

 var secondstonow: Int {
     let components = Set<Calendar.Component>([.second])
     return Calendar.current.dateComponents(components, from: self, to: Date()).second ?? 0
 }

 var daystonow: Int {
     let components = Set<Calendar.Component>([.day])
     return Calendar.current.dateComponents(components, from: self, to: Date()).day ?? 0
 }

 var weekstonow: Int {
     let components = Set<Calendar.Component>([.weekOfYear])
     return Calendar.current.dateComponents(components, from: self, to: Date()).weekOfYear ?? 0
 }

 static func == (lhs: Date, rhs: Date) -> Bool {
     return lhs.compare(rhs) == ComparisonResult.orderedSame
 }

 static func < (lhs: Date, rhs: Date) -> Bool {
     return lhs.compare(rhs) == ComparisonResult.orderedAscending
 }

 init(year: Int, month: Int, day: Int) {
     let calendar = Calendar.current
     var dateComponent = DateComponents()
     dateComponent.year = year
     dateComponent.month = month
     dateComponent.day = day
     self = calendar.date(from: dateComponent)!
 }
  */
