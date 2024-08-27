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
        return dateComponent.day!
    }

    func getWeekday() -> Int {
        let calendar = Calendar.current
        return (calendar as NSCalendar).components(.weekday, from: self).weekday!
    }

    func isSelectedDayofWeek(day: NumDayofweek) -> Bool {
        getWeekday() == day.rawValue
    }

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

    func en_us_string_from_date() -> String {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en_US")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
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
}

extension String {
    func en_us_date_from_string() -> Date {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en_US")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter.date(from: self) ?? Date()
    }

    func localized_date_from_string() -> Date {
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        return dateformatter.date(from: self) ?? Date()
    }
}

/*

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
