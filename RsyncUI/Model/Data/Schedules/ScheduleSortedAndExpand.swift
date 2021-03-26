//
//  ScheduleSortedAndExpand.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 26/03/2021.
//

import Foundation

class ScheduleSortedAndExpand {
    var expandedData: [NSMutableDictionary]?
    var sortedschedules: [NSMutableDictionary]?
    var schedulesNSDictionary: [NSMutableDictionary]?

    // Calculate daily schedules
    private func daily(dateStart: Date, schedule: String, dict: NSDictionary) {
        let calendar = Calendar.current
        var days: Int?
        if dateStart.daystonow == Date().daystonow, dateStart > Date() {
            days = dateStart.daystonow
        } else {
            days = dateStart.daystonow + 1
        }
        let components = DateComponents(day: days)
        if let start: Date = calendar.date(byAdding: components, to: dateStart) {
            if start.timeIntervalSinceNow > 0 {
                if let hiddenID = (dict.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) {
                    let profilename = dict.value(forKey: DictionaryStrings.profilename.rawValue) ?? NSLocalizedString("Default profile", comment: "default profile")
                    let time = start.timeIntervalSinceNow
                    let dictschedule: NSMutableDictionary = [
                        DictionaryStrings.start.rawValue: start,
                        DictionaryStrings.hiddenID.rawValue: hiddenID,
                        DictionaryStrings.dateStart.rawValue: dateStart,
                        DictionaryStrings.schedule.rawValue: schedule,
                        DictionaryStrings.timetostart.rawValue: time,
                        DictionaryStrings.profilename.rawValue: profilename,
                    ]
                    self.expandedData?.append(dictschedule)
                }
            }
        }
    }

    // Calculate weekly schedules
    private func weekly(dateStart: Date, schedule: String, dict: NSDictionary) {
        let calendar = Calendar.current
        var weekofyear: Int?
        if dateStart.weekstonow == Date().weekstonow, dateStart > Date() {
            weekofyear = dateStart.weekstonow
        } else {
            weekofyear = dateStart.weekstonow + 1
        }
        let components = DateComponents(weekOfYear: weekofyear)
        if let start: Date = calendar.date(byAdding: components, to: dateStart) {
            if start.timeIntervalSinceNow > 0 {
                if let hiddenID = (dict.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) {
                    let profilename = dict.value(forKey: DictionaryStrings.profilename.rawValue) ?? NSLocalizedString("Default profile", comment: "default profile")
                    let time = start.timeIntervalSinceNow
                    let dictschedule: NSMutableDictionary = [
                        DictionaryStrings.start.rawValue: start,
                        DictionaryStrings.hiddenID.rawValue: hiddenID,
                        DictionaryStrings.dateStart.rawValue: dateStart,
                        DictionaryStrings.schedule.rawValue: schedule,
                        DictionaryStrings.timetostart.rawValue: time,
                        DictionaryStrings.profilename.rawValue: profilename,
                    ]
                    self.expandedData?.append(dictschedule)
                }
            }
        }
    }

    // Expanding and sorting Scheduledata
    private func sortAndExpandScheduleTasks() {
        for i in 0 ..< (self.schedulesNSDictionary?.count ?? 0) {
            let dict = self.schedulesNSDictionary![i]
            let dateStop: Date = (dict.value(forKey: DictionaryStrings.dateStop.rawValue) as? String)?.en_us_date_from_string() ?? Date()
            let dateStart: Date = (dict.value(forKey: DictionaryStrings.dateStart.rawValue) as? String)?.en_us_date_from_string() ?? Date()
            let schedule: String = (dict.value(forKey: DictionaryStrings.schedule.rawValue) as? String) ?? Scheduletype.once.rawValue
            let seconds: Double = dateStop.timeIntervalSinceNow
            // Get all jobs which are not executed
            if seconds > 0 {
                switch schedule {
                case Scheduletype.once.rawValue:
                    if let hiddenID = (dict.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) {
                        let profilename = dict.value(forKey: DictionaryStrings.profilename.rawValue) ?? NSLocalizedString("Default profile", comment: "default profile")
                        let time = seconds
                        let dictschedule: NSMutableDictionary = [
                            DictionaryStrings.start.rawValue: dateStart,
                            DictionaryStrings.hiddenID.rawValue: hiddenID,
                            DictionaryStrings.dateStart.rawValue: dateStart,
                            DictionaryStrings.schedule.rawValue: schedule,
                            DictionaryStrings.timetostart.rawValue: time,
                            DictionaryStrings.profilename.rawValue: profilename,
                        ]
                        self.expandedData?.append(dictschedule)
                    }
                case Scheduletype.daily.rawValue:
                    self.daily(dateStart: dateStart, schedule: schedule, dict: dict)
                case Scheduletype.weekly.rawValue:
                    self.weekly(dateStart: dateStart, schedule: schedule, dict: dict)
                default:
                    break
                }
            }
            self.sortedschedules = self.expandedData?.sorted { (date1, date2) -> Bool in
                if let date1 = date1.value(forKey: DictionaryStrings.start.rawValue) as? Date {
                    if let date2 = date2.value(forKey: DictionaryStrings.start.rawValue) as? Date {
                        if date1.timeIntervalSince(date2) > 0 {
                            return false
                        } else {
                            return true
                        }
                    }
                }
                return false
            }
        }
        self.adddelta()
    }

    private func adddelta() {
        // calculate delta time
        guard (self.sortedschedules?.count ?? 0) > 1 else { return }
        let timestring = Dateandtime()
        self.sortedschedules?[0].setValue(timestring.timestring(seconds: 0), forKey: DictionaryStrings.delta.rawValue)
        if let timetostart = self.sortedschedules?[0].value(forKey: DictionaryStrings.timetostart.rawValue) as? Double {
            self.sortedschedules?[0].setValue(timestring.timestring(seconds: timetostart), forKey: DictionaryStrings.startsin.rawValue)
        }
        self.sortedschedules?[0].setValue(0, forKey: "queuenumber")
        for i in 1 ..< (self.sortedschedules?.count ?? 0) {
            if let t1 = self.sortedschedules?[i - 1].value(forKey: DictionaryStrings.timetostart.rawValue) as? Double {
                if let t2 = self.sortedschedules?[i].value(forKey: DictionaryStrings.timetostart.rawValue) as? Double {
                    self.sortedschedules?[i].setValue(timestring.timestring(seconds: t2 - t1), forKey: DictionaryStrings.delta.rawValue)
                    self.sortedschedules?[i].setValue(i, forKey: "queuenumber")
                    self.sortedschedules?[i].setValue(timestring.timestring(seconds: t2), forKey: DictionaryStrings.startsin.rawValue)
                }
            }
        }
    }

    typealias Futureschedules = (Int, Double)

    // Calculates number of future Schedules ID by hiddenID
    func numberoftasks(_ hiddenID: Int) -> Futureschedules {
        if let result = self.sortedschedules?.filter({ (($0.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) == hiddenID) }) {
            guard result.count > 0 else { return (0, 0) }
            let timetostart = result[0].value(forKey: DictionaryStrings.timetostart.rawValue) as? Double ?? 0
            return (result.count, timetostart)
        }
        return (0, 0)
    }

    func sortandcountscheduledonetask(_ hiddenID: Int, profilename: String?, number: Bool) -> String {
        var result: [NSDictionary]?
        if profilename != nil {
            result = self.sortedschedules?.filter { (($0.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) == hiddenID
                    && ($0.value(forKey: DictionaryStrings.start.rawValue) as? Date)?.timeIntervalSinceNow ?? -1 > 0)
                && ($0.value(forKey: DictionaryStrings.profilename.rawValue) as? String) == profilename ?? ""
            }
        } else {
            result = self.sortedschedules?.filter { (($0.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) == hiddenID
                    && ($0.value(forKey: DictionaryStrings.start.rawValue) as? Date)?.timeIntervalSinceNow ?? -1 > 0)
                && ($0.value(forKey: DictionaryStrings.profilename.rawValue) as? String) == NSLocalizedString("Default profile", comment: "default profile") ||
                ($0.value(forKey: DictionaryStrings.profilename.rawValue) as? String) == ""
            }
        }
        guard result != nil else { return "" }
        let sorted = result?.sorted { (di1, di2) -> Bool in
            if let d1 = di1.value(forKey: DictionaryStrings.start.rawValue) as? Date, let d2 = di2.value(forKey: DictionaryStrings.start.rawValue) as? Date {
                if d1.timeIntervalSince(d2) > 0 {
                    return false
                } else {
                    return true
                }
            }
            return false
        }
        guard (sorted?.count ?? 0) > 0 else { return "" }
        if number {
            if let firsttask = (sorted?[0].value(forKey: DictionaryStrings.start.rawValue) as? Date)?.timeIntervalSinceNow {
                return Dateandtime().timestring(seconds: firsttask)
            } else {
                return ""
            }
        } else {
            let type = sorted?[0].value(forKey: DictionaryStrings.schedule.rawValue) as? String
            return type ?? ""
        }
    }

    init() {
        self.expandedData = [NSMutableDictionary]()
        self.sortAndExpandScheduleTasks()
    }
}

