//
//  Tagsnapshots.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/12/2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

final class TagSnapshots {
    var day: NumDayofweek?
    var nameofday: StringDayofweek?
    var daylocalized = [NSLocalizedString("Sunday", comment: "plan"),
                        NSLocalizedString("Monday", comment: "plan"),
                        NSLocalizedString("Tuesday", comment: "plan"),
                        NSLocalizedString("Wednesday", comment: "plan"),
                        NSLocalizedString("Thursday", comment: "plan"),
                        NSLocalizedString("Friday", comment: "plan"),
                        NSLocalizedString("Saturday", comment: "plan")]
    var logrecordssnapshot: [Logrecordsschedules]?
    private var numberoflogs: Int?
    private var keepallselcteddayofweek: Bool = true
    var now: String?

    func islastSundayinMonth(date: Date) -> Bool {
        if date.isSunday(), date.daymonth() > 24 {
            return true
        } else {
            return false
        }
    }

    func isaSunday(date: Date) -> Bool {
        return date.isSunday()
    }

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
                logrecordssnapshot?[index].selectsnap = 0
            } else if currentdaymonth(index: index) {
                logrecordssnapshot?[index].selectsnap = 1
            } else {
                if keepallorlastdayinperiod(index: index) {
                    logrecordssnapshot?[index].selectsnap = 1
                }
            }
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
            let tag = NSLocalizedString("Keep", comment: "plan") + " " + NSLocalizedString("this week", comment: "plan")
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
                if datefromstring(datestringlocalized: datesnapshotstring).isSelectedDayofWeek(day: self.day!) == false {
                    let tag = NSLocalizedString("Delete", comment: "plan") + " " + day + ", " + month + " " + NSLocalizedString("this month", comment: "plan")
                    logrecordssnapshot?[index].period = tag
                    return true
                } else {
                    let tag = NSLocalizedString("Keep", comment: "plan") + " " + month + " " + daylocalized[self.day!.rawValue - 1] + " " + NSLocalizedString("this month", comment: "plan")
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
        var check: Keepallorlastdayinperiodfunc?
        if keepallselcteddayofweek {
            check = isselectedDayinWeek
        } else {
            check = islastSelectedDayinMonth
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
                        let tag = NSLocalizedString("Keep", comment: "plan") + " " + day + ", " + month + " " + NSLocalizedString("previous month", comment: "plan")
                        logrecordssnapshot?[index].period = tag
                    } else {
                        let tag = NSLocalizedString("Keep", comment: "plan") + " " + day + ", " + month + " " + NSLocalizedString("earlier months", comment: "plan")
                        logrecordssnapshot?[index].period = tag
                    }
                    return false
                } else {
                    let date = datefromstring(datestringlocalized: datesnapshotstring)
                    if date.ispreviousmont {
                        let tag = NSLocalizedString("Delete", comment: "plan") + " " + day + ", " + month + " " + NSLocalizedString("previous month", comment: "plan")
                        logrecordssnapshot?[index].period = tag
                    } else {
                        let tag = NSLocalizedString("Delete", comment: "plan") + " " + day + ", " + month + " " + NSLocalizedString("earlier months", comment: "plan")
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
        if date.isSelectedDayofWeek(day: day!), date.daymonth() > 24 {
            return true
        } else {
            return false
        }
    }

    func isselectedDayinWeek(_ date: Date) -> Bool {
        return day!.rawValue == date.getWeekday()
    }

    private func reset() {
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) {
            logrecordssnapshot?[i].selectsnap = 0
        }
    }

    private func setweekdaytokeep(snapdayoffweek: String) {
        switch snapdayoffweek {
        case StringDayofweek.Monday.rawValue:
            day = .Monday
            nameofday = .Monday
        case StringDayofweek.Tuesday.rawValue:
            day = .Tuesday
            nameofday = .Tuesday
        case StringDayofweek.Wednesday.rawValue:
            day = .Wednesday
            nameofday = .Wednesday
        case StringDayofweek.Thursday.rawValue:
            day = .Thursday
            nameofday = .Thursday
        case StringDayofweek.Friday.rawValue:
            day = .Friday
            nameofday = .Friday
        case StringDayofweek.Saturday.rawValue:
            day = .Saturday
            nameofday = .Saturday
        case StringDayofweek.Sunday.rawValue:
            day = .Sunday
            nameofday = .Sunday
        default:
            day = .Sunday
            nameofday = .Sunday
        }
    }

    init(plan: Int,
         snapdayoffweek: String,
         data: [Logrecordsschedules]?)
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
        numberoflogs = logrecordssnapshot?.count ?? 0
        now = Date().localized_string_from_date()
        reset()
        markfordelete()
    }

    deinit {
        // print("deinit TagSnapshots")
    }
}
