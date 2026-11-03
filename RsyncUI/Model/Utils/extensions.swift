//
//  extensions.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 08/12/2018.
//

import Foundation

private enum EnglishDateParser {
    private static let lock = NSLock()
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.dateFormat = "dd MMM yyyy HH:mm"
        return formatter
    }()

    static func date(from string: String) -> Date? {
        lock.withLock {
            formatter.date(from: string)
        }
    }
}

extension Date {
    func dayMonth() -> Int {
        Calendar.current.component(.day, from: self)
    }

    func getWeekday() -> Int {
        Calendar.current.component(.weekday, from: self)
    }

    func isSelectedDayOfWeek(day: NumDayofweek) -> Bool {
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

    func localized_string_from_date() -> String {
        formatted(date: .abbreviated, time: .shortened)
    }

    func long_localized_string_from_date() -> String {
        formatted(date: .abbreviated, time: .complete)
    }

    func en_string_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter.string(from: self)
    }

    func shortlocalized_string_from_date() -> String {
        // MM-dd-yyyy HH:mm
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "MM-dd-yyyy:HH:mm"
        return dateformatter.string(from: self)
    }

    func localized_weekday_from_date() -> String {
        formatted(.dateTime.weekday(.wide))
    }

    func localized_month_from_date() -> String {
        formatted(.dateTime.month(.wide))
    }
}

extension String {
    func en_date_from_string() -> Date {
        EnglishDateParser.date(from: self) ?? Date()
    }

    func validate_en_date_from_string() -> Date? {
        EnglishDateParser.date(from: self)
    }

    func localized_date_from_string() -> Date {
        let strategy = Date.FormatStyle(date: .abbreviated, time: .shortened).parseStrategy
        return (try? Date(self, strategy: strategy)) ?? Date()
    }
}

extension Double {
    func latest() -> String {
        let seconds = self

        // Less than 1 minute (60 seconds)
        if seconds < 60 {
            let secondsValue = Int(seconds)
            return secondsValue == 1 ? String(localized: "\(secondsValue) second") : String(localized: "\(secondsValue) seconds")
        }
        // Less than 1 hour (3600 seconds)
        else if seconds < 3600 {
            let minutes = seconds / 60
            return minutes < 2 ? String(format: String(localized: "%.0f min"), minutes) : String(format: String(localized: "%.0f mins"), minutes)
        }
        // Less than 1 day (86400 seconds)
        else if seconds < 86400 {
            let hours = seconds / 3600
            return hours < 2 ? String(format: String(localized: "%.1f hour"), hours) : String(format: String(localized: "%.1f hours"), hours)
        }
        // 1 day or more
        else {
            let days = seconds / 86400
            return days < 2 ? String(format: String(localized: "%.1f day"), days) : String(format: String(localized: "%.1f days"), days)
        }
    }
}
