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
    var daylocalized = ["Sunday",
                        "Monday",
                        "Tuesday",
                        "Wednesday",
                        "Thursday",
                        "Friday",
                        "Saturday"]
    var logrecordssnapshot: [LogRecordSnapshot]?
    private var keepallselcteddayofweek: Bool = true
    var now: String?

    private func datefromstring(datestringlocalized: String) -> Date {
        guard datestringlocalized != "no log" else { return Date() }
        return datestringlocalized.localized_date_from_string()
    }

    private func datecomponentsfromstring(datestringlocalized: String?) -> DateComponents {
        var date: Date?
        if datestringlocalized != nil {
            date = datefromstring(datestringlocalized: datestringlocalized!)
        }
        let calendar = Calendar.current
        return calendar.dateComponents([.calendar, .timeZone,
                                        .year, .month, .day,
                                        .hour, .minute,
                                        .weekday, .weekOfYear, .year], from: date ?? Date())
    }

    private func markfordelete() {
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) {
            let index = (logrecordssnapshot?.count ?? 0) - 1 - i
            if currentweek(index: index) {
            } else if currentdaymonth(index: index) {
            } else { if keepallorlastdayinperiod(index: index) {} }
        }
    }

    // Keep all snapshots current week.
    private func currentweek(index: Int) -> Bool {
        let datesnapshotstring = logrecordssnapshot?[index].dateExecuted
        if datecomponentsfromstring(datestringlocalized: datesnapshotstring).weekOfYear ==
            datecomponentsfromstring(datestringlocalized: now).weekOfYear,
            datecomponentsfromstring(datestringlocalized: datesnapshotstring).year ==
            datecomponentsfromstring(datestringlocalized: now).year
        {
            let tag = "Keep" + " " + "this week"
            logrecordssnapshot?[index].period = tag
            return true
        }
        return false
    }

    // Keep snapshots every choosen day this month ex current week
    private func currentdaymonth(index: Int) -> Bool {
        if let datesnapshotstring = logrecordssnapshot?[index].dateExecuted {
            let month = datefromstring(datestringlocalized: datesnapshotstring).monthNameShort()
            let day = datefromstring(datestringlocalized: datesnapshotstring).dayNameShort()
            if datecomponentsfromstring(datestringlocalized: datesnapshotstring).month ==
                datecomponentsfromstring(datestringlocalized: now).month,
                datecomponentsfromstring(datestringlocalized: datesnapshotstring).year == datecomponentsfromstring(datestringlocalized: now).year
            {
                if datefromstring(datestringlocalized: datesnapshotstring).isSelectedDayofWeek(day: self.day) == false {
                    let tag = "Delete" + " " + day + ", " + month + " " + "this month"
                    logrecordssnapshot?[index].period = tag
                    return true
                } else {
                    let tag = "Keep" + " " + month + " " + daylocalized[self.day.rawValue - 1] + " " + "this month"
                    logrecordssnapshot?[index].period = tag
                    return false
                }
            }
            return false
        }
        return false
    }

    typealias Keepallorlastdayinperiodfunc = (Date) -> Bool

    func keepallorlastdayinperiod(index: Int) -> Bool {
        let check: Keepallorlastdayinperiodfunc? = if keepallselcteddayofweek {
            isselectedDayinWeek
        } else {
            islastSelectedDayinMonth
        }
        if let datesnapshotstring = logrecordssnapshot?[index].dateExecuted {
            let month = datefromstring(datestringlocalized: datesnapshotstring).monthNameShort()
            let day = datefromstring(datestringlocalized: datesnapshotstring).dayNameShort()
            if datecomponentsfromstring(datestringlocalized: datesnapshotstring).month !=
                datecomponentsfromstring(datestringlocalized: now).month ||
                datecomponentsfromstring(datestringlocalized: datesnapshotstring).year! <
                datecomponentsfromstring(datestringlocalized: now).year!
            {
                if check!(datefromstring(datestringlocalized: datesnapshotstring)) == true {
                    if datecomponentsfromstring(datestringlocalized: datesnapshotstring).month == datecomponentsfromstring(datestringlocalized: now).month! - 1 {
                        let tag = "Keep" + " " + day + ", " + month + " " + "previous month"
                        logrecordssnapshot?[index].period = tag
                    } else {
                        let tag = "Keep" + " " + day + ", " + month + " " + "earlier months"
                        logrecordssnapshot?[index].period = tag
                    }
                    return false
                } else {
                    let date = datefromstring(datestringlocalized: datesnapshotstring)
                    if date.ispreviousmont {
                        let tag = "Delete" + " " + day + ", " + month + " " + "previous month"
                        logrecordssnapshot?[index].period = tag
                    } else {
                        let tag = "Delete" + " " + day + ", " + month + " " + "earlier months"
                        logrecordssnapshot?[index].period = tag
                    }
                    return true
                }
            }
            return false
        }
        return false
    }

    func islastSelectedDayinMonth(_ date: Date) -> Bool {
        if date.isSelectedDayofWeek(day: day), date.daymonth() > 24 {
            true
        } else {
            false
        }
    }

    func isselectedDayinWeek(_ date: Date) -> Bool {
        day.rawValue == date.getWeekday()
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
        now = Date().localized_string_from_date()
        markfordelete()
    }
}

// swiftlint:enable line_length
