//
//  SingletaskPrimaryLogging.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/01/2021.
//

import Foundation

class SingletaskPrimaryLogging {
    var structconfigurations: [Configuration]?
    var structschedules: [ConfigurationSchedule]?
    var localeprofile: String?
    var localehiddenID: Int?

    func setCurrentDateonConfiguration() {
        if let hiddenID = localehiddenID,
           let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID })
        {
            // Caution, snapshotnum already increased before logrecord
            if structconfigurations?[index].task == SharedReference.shared.snapshot {
                increasesnapshotnum(index: index)
            }
            let currendate = Date()
            structconfigurations?[index].dateRun = currendate.en_us_string_from_date()
            PersistentStorage(profile: localeprofile,
                              whattoreadorwrite: .configuration,
                              readonly: false,
                              configurations: structconfigurations,
                              schedules: nil)
                .saveMemoryToPersistentStore()
        }
    }

    func increasesnapshotnum(index: Int) {
        if let num = structconfigurations?[index].snapshotnum {
            structconfigurations?[index].snapshotnum = num + 1
        }
    }

    // Caution, the snapshotnum is alrady increased in setCurrentDateonConfiguration().
    // Must set -1 to get correct num in log
    func addlogpermanentstore(outputprocess: OutputProcess?) {
        if let hiddenID = localehiddenID {
            if SharedReference.shared.detailedlogging {
                let stats = Numbers(outputprocess: outputprocess).stats()
                // Set the current date
                let currendate = Date()
                let date = currendate.en_us_string_from_date()
                if let config = getconfig(hiddenID: hiddenID) {
                    var resultannotaded: String?
                    if config.task == SharedReference.shared.snapshot {
                        if let snapshotnum = config.snapshotnum {
                            resultannotaded = "(" + String(snapshotnum - 1) + ") " + stats
                        } else {
                            resultannotaded = "(" + "1" + ") " + stats
                        }
                    } else {
                        resultannotaded = stats
                    }
                    var inserted: Bool = addlogexisting(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
                    // Record does not exist, create new Schedule (not inserted)
                    if inserted == false {
                        inserted = addlognew(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
                    }
                    if inserted {
                        PersistentStorage(profile: localeprofile,
                                          whattoreadorwrite: .schedule,
                                          readonly: false,
                                          configurations: nil,
                                          schedules: structschedules)
                            .saveMemoryToPersistentStore()
                    }
                    _ = Logfile(outputprocess)
                }
            }
        }
    }

    func addlogexisting(hiddenID: Int, result: String, date: String) -> Bool {
        let configdata = GetConfigurationData(configurations: structconfigurations)
        if SharedReference.shared.synctasks.contains(configdata.getconfigurationdata(hiddenID, resource: .task) ?? "") {
            if let index = structschedules?.firstIndex(where: { $0.hiddenID == hiddenID
                    && $0.schedule == Scheduletype.manuel.rawValue
                    && $0.dateStart == "01 Jan 1900 00:00"
            }) {
                var log = Log()
                log.dateExecuted = date
                log.resultExecuted = result
                structschedules?[index].logrecords?.append(log)
                return true
            }
        }
        return false
    }

    func addlognew(hiddenID: Int, result: String, date: String) -> Bool {
        let configdata = GetConfigurationData(configurations: structconfigurations)
        if SharedReference.shared.synctasks.contains(configdata.getconfigurationdata(hiddenID, resource: .task) ?? "") {
            let main = NSMutableDictionary()
            main.setObject(hiddenID, forKey: DictionaryStrings.hiddenID.rawValue as NSCopying)
            main.setObject("01 Jan 1900 00:00", forKey: DictionaryStrings.dateStart.rawValue as NSCopying)
            main.setObject(Scheduletype.manuel.rawValue, forKey: DictionaryStrings.schedule.rawValue as NSCopying)
            let dict = NSMutableDictionary()
            dict.setObject(date, forKey: DictionaryStrings.dateExecuted.rawValue as NSCopying)
            dict.setObject(result, forKey: DictionaryStrings.resultExecuted.rawValue as NSCopying)
            let executed = NSMutableArray()
            executed.add(dict)
            let newSchedule = ConfigurationSchedule(dictionary: main, log: executed)
            structschedules?.append(newSchedule)
            return true
        }
        return false
    }

    func getconfig(hiddenID: Int) -> Configuration? {
        if let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return structconfigurations?[index]
        }
        return nil
    }

    func deleteselectedlogs(uuids: Set<UUID>, hiddenID: Int) {
        if let logrecords = getalllogsbyhiddenID(hiddenID: hiddenID) {
            let selectedlogrecords = logrecords.filter { uuids.contains($0.id) }
            // TODO: implement
            // print(selectedlogrecords)
            // print(selectedlogrecords.count)
        }
    }

    func getalllogsbyhiddenID(hiddenID: Int) -> [Log]? {
        var joined: [Log]?
        let schedulerecords = structschedules?.filter { $0.hiddenID == hiddenID }
        if (schedulerecords?.count ?? 0) > 0 {
            joined = [Log]()
            for i in 0 ..< (schedulerecords?.count ?? 0) {
                if let logrecords = schedulerecords?[i].logrecords {
                    joined?.append(contentsOf: logrecords)
                }
            }
            return joined?.sorted(by: \.date, using: >)
        }
        return nil
    }

    init(profile: String?,
         hiddenID: Int?,
         configurations: [Configuration]?,
         scheduleConfigurations: [ConfigurationSchedule]?)
    {
        localeprofile = profile
        localehiddenID = hiddenID
        structconfigurations = configurations
        structschedules = scheduleConfigurations
    }

    deinit {
        // print("deinit SingletaskPrimaryLogging")
    }
}
