//
//  TagSnapshots.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/12/2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

final class TagSnapshots {
    var day: NumDayofweek = .Monday
    var logrecordssnapshot: [LogRecordSnapshot]?
    private var keepallselcteddayofweek: Bool = true

    private func markfordelete() {
        if var index = logrecordssnapshot?.count, let logrecordssnapshot {
            index -= 1
            _ = logrecordssnapshot.map { _ in
                index -= 1
                guard index >= 0 else { return }
                if currentweek(index: index) {
                } else if currentdaymonth(index: index) {
                } else { if keepallorlastdayinperiod(index: index) {} }
            }
        }
    }

    private func currentweek(index: Int) -> Bool {
        if let datesnapshot = logrecordssnapshot?[index].dateExecuted.localized_date_from_string() {
            if datecomponentsfromdate(localizeddate: datesnapshot).weekOfYear ==
                datecomponentsfromdate(localizeddate: Date()).weekOfYear,
                datecomponentsfromdate(localizeddate: datesnapshot).year ==
                datecomponentsfromdate(localizeddate: Date()).year
            {
                if logrecordssnapshot?[index].resultExecuted != "no record" {
                    logrecordssnapshot?[index].period = "Keep" + " " + "this week"
                }
                return true
            }
            return false
        }
        return false
    }

    // Keep snapshots every choosen day this month ex current week
    private func currentdaymonth(index: Int) -> Bool {
        if let datesnapshot = logrecordssnapshot?[index].dateExecuted.localized_date_from_string() {
            let year = datecomponentsfromdate(localizeddate: datesnapshot).year
            let month = datecomponentsfromdate(localizeddate: datesnapshot).month

            let monthToday = datecomponentsfromdate(localizeddate: Date()).month
            let yearToday = datecomponentsfromdate(localizeddate: Date()).year

            if month == monthToday, year == yearToday {
                if datesnapshot.isSelectedDayofWeek(day: day) == false {
                    let tag = "Delete" + " " + datesnapshot.localized_weekday_from_date() + ", "
                        + datesnapshot.localized_month_from_date() + " " + "this month"

                    logrecordssnapshot?[index].period = tag
                    return true
                } else {
                    let tag = "Keep" + " " + datesnapshot.localized_weekday_from_date() + ", "
                        + datesnapshot.localized_month_from_date() + " " + "this month"
                    logrecordssnapshot?[index].period = tag
                    return false
                }
            }
            return false
        }
        return false
    }

    private func datecomponentsfromdate(localizeddate: Date) -> DateComponents {
        let calendar = Calendar.current
        return calendar.dateComponents([.calendar, .timeZone,
                                        .year, .month, .day,
                                        .hour, .minute,
                                        .weekday, .weekOfYear, .year], from: localizeddate)
    }

    func keepallorlastdayinperiod(index: Int) -> Bool {
        if let datesnapshot = logrecordssnapshot?[index].dateExecuted.localized_date_from_string() {
            if let year = datecomponentsfromdate(localizeddate: datesnapshot).year,
               let month = datecomponentsfromdate(localizeddate: datesnapshot).month,
               let monthToday = datecomponentsfromdate(localizeddate: Date()).month,
               let yearToday = datecomponentsfromdate(localizeddate: Date()).year
            {
                if month != monthToday || year < yearToday {
                    if verifydaytokeepinmonth(datesnapshot) == true {
                        if month == monthToday - 1 {
                            let tag = "Keep" + " " + datesnapshot.localized_weekday_from_date() + ", "
                                + datesnapshot.localized_month_from_date() + " " +  "previous month"
                            logrecordssnapshot?[index].period = tag
                        } else {
                            let tag = "Keep" + " " + datesnapshot.localized_weekday_from_date() + ", "
                                + datesnapshot.localized_month_from_date() + " " + "earlier months"
                            logrecordssnapshot?[index].period = tag
                        }
                        return false
                    } else {
                        if datesnapshot.ispreviousmont {
                            let tag = "Delete" + " " + datesnapshot.localized_weekday_from_date() + ", "
                                + datesnapshot.localized_month_from_date() + " " + "previous month"
                            logrecordssnapshot?[index].period = tag
                        } else {
                            let tag = "Delete" + " " + datesnapshot.localized_weekday_from_date() + ", "
                                + datesnapshot.localized_month_from_date() + " " + "earlier months"
                            logrecordssnapshot?[index].period = tag
                        }
                        return true
                    }
                }
            }

            return false
        }
        return false
    }

    func verifydaytokeepinmonth(_ date: Date) -> Bool {
        if keepallselcteddayofweek {
            day.rawValue == date.getWeekday()
        } else {
            if date.isSelectedDayofWeek(day: day), date.daymonth() > 24 {
                true
            } else {
                false
            }
        }
    }

    private func setweekdaytokeep(snapdayoffweek: String) {
        switch snapdayoffweek {
        case StringDayofweek.Monday.rawValue:
            day = .Monday
        case StringDayofweek.Tuesday.rawValue:
            day = .Tuesday
        case StringDayofweek.Wednesday.rawValue:
            day = .Wednesday
        case StringDayofweek.Thursday.rawValue:
            day = .Thursday
        case StringDayofweek.Friday.rawValue:
            day = .Friday
        case StringDayofweek.Saturday.rawValue:
            day = .Saturday
        case StringDayofweek.Sunday.rawValue:
            day = .Sunday
        default:
            day = .Sunday
        }
    }

    init(plan: Int,
         snapdayoffweek: String,
         data: [LogRecordSnapshot]?)
    {
        // which plan to apply
        if plan == 1 {
            keepallselcteddayofweek = true
        } else {
            keepallselcteddayofweek = false
        }
        setweekdaytokeep(snapdayoffweek: snapdayoffweek)
        logrecordssnapshot = data
        guard logrecordssnapshot != nil else { return }

        markfordelete()
    }
}
