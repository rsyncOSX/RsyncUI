//
//  VerifyJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length opening_brace

import Foundation

enum VerifyJSONError: LocalizedError {
    case verifyconfig
    case verifyschedule

    var errorDescription: String? {
        switch self {
        case .verifyconfig:
            return NSLocalizedString("Verify JSON, configurations: check logfile", comment: "VerifyJSONError")
        case .verifyschedule:
            return NSLocalizedString("Verify JSON, schedules: check logfile", comment: "VerifyJSONError")
        }
    }
}

final class VerifyJSON {
    // Plist
    var plistconfigurations: [Configuration]?
    var plistschedules: [ConfigurationSchedule]?
    // JSON
    var jsonconfigurations: [DecodeConfiguration]?
    var jsonschedules: [DecodeSchedule]?
    var transformedconfigurations: [Configuration]?
    var transformedschedules: [ConfigurationSchedule]?
    var localprofile: String?
    // Result of verify
    var verifyconf: Bool?
    var verifysched: Bool?
    // valid hiddenIDS
    var validplisthiddenID: Set<Int>?
    var validjsonhiddenID: Set<Int>?

    func readschedulesplist() {
        let store = PersistentStorageSchedulingPLIST(profile: localprofile,
                                                     readonly: true,
                                                     schedules: nil).schedulesasdictionary
        var schedules = [ConfigurationSchedule]()
        var schedule: ConfigurationSchedule?
        for i in 0 ..< (store?.count ?? 0) {
            if let dict = store?[i], let validplisthiddenID = self.validplisthiddenID {
                if let hiddenID = dict.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int {
                    if validplisthiddenID.contains(hiddenID) {
                        if let log = dict.value(forKey: DictionaryStrings.executed.rawValue) {
                            schedule = ConfigurationSchedule(dictionary: dict, log: log as? NSArray)
                        } else {
                            schedule = ConfigurationSchedule(dictionary: dict, log: nil)
                        }
                        schedule?.profilename = localprofile
                        if let conf = schedule { schedules.append(conf) }
                    }
                }
            }
        }
        plistschedules = schedules
    }

    func readschedulesJSON() {
        let store = PersistentStorageSchedulingJSON(profile: localprofile,
                                                    readonly: true,
                                                    schedules: nil)
        jsonschedules = store.decodedjson as? [DecodeSchedule]
        if let jsonschedules = self.jsonschedules, let validjsonhiddenID = self.validjsonhiddenID {
            transformedschedules = [ConfigurationSchedule]()
            let transform = TransformSchedulefromJSON()
            for i in 0 ..< jsonschedules.count {
                var transformed = transform.transform(object: jsonschedules[i])
                transformed.profilename = localprofile
                if validjsonhiddenID.contains(transformed.hiddenID) {
                    transformedschedules?.append(transformed)
                }
            }
        }
    }

    func readconfigurationsplist() {
        let store = PersistentStorageConfigurationPLIST(profile: localprofile,
                                                        readonly: true,
                                                        configurations: nil)
            .configurationsasdictionary
        var configurations = [Configuration]()
        for i in 0 ..< (store?.count ?? 0) {
            if let dict = store?[i] {
                let config = Configuration(dictionary: dict)
                if SharedReference.shared.synctasks.contains(config.task) {
                    configurations.append(config)
                    validplisthiddenID?.insert(config.hiddenID)
                }
            }
        }
        plistconfigurations = configurations
    }

    func readconfigurationsJSON() {
        let store = PersistentStorageConfigurationJSON(profile: localprofile,
                                                       readonly: true,
                                                       configurations: nil)
        jsonconfigurations = store.decodedjson as? [DecodeConfiguration]
        if let jsonconfigurations = self.jsonconfigurations {
            transformedconfigurations = [Configuration]()
            let transform = TransformConfigfromJSON()
            for i in 0 ..< jsonconfigurations.count {
                let transformed = transform.transform(object: jsonconfigurations[i])
                if SharedReference.shared.synctasks.contains(transformed.task) {
                    transformedconfigurations?.append(transformed)
                    validjsonhiddenID?.insert(transformed.hiddenID)
                }
            }
        }
    }

    func verifyconfigurations() throws {
        guard (plistconfigurations?.count ?? 0) == (transformedconfigurations?.count ?? 0) else {
            let errorstring = "Configurations: not equal number of records." + "\n" + "Stopping further verify of Configurations..."
            logerror(str: errorstring)
            throw VerifyJSONError.verifyconfig
        }
        if let plistconfigurations = self.plistconfigurations,
           let transformedconfigurations = self.transformedconfigurations
        {
            for i in 0 ..< plistconfigurations.count {
                guard Equal().isequalstructs(rhs: plistconfigurations[i], lhs: transformedconfigurations[i]) == true else {
                    let errorstring = "Configurations in record " + String(i) + ": not equal..." + "\n" + "Stopping further verify of Configurations..."
                    logerror(str: errorstring)
                    throw VerifyJSONError.verifyconfig
                }
            }
        }
        logerror(str: "...verify of Configurations seems OK...")
    }

    func verifyschedules() throws {
        guard (plistschedules?.count ?? 0) == (transformedschedules?.count ?? 0) else {
            let errorstring = "Schedules: not equal number of records." + "\n" + "Stopping further verify of Schedules..."
            logerror(str: errorstring)
            throw VerifyJSONError.verifyschedule
        }
        if let plistschedules = self.plistschedules,
           let transformedschedules = self.transformedschedules
        {
            for i in 0 ..< plistschedules.count {
                guard plistschedules[i].logrecords?.count == transformedschedules[i].logrecords?.count else {
                    let errorstring = "Logrecord " + String(plistschedules[i].logrecords?.count ?? 0) + " in plist not equal in JSON " +
                        String(transformedschedules[i].logrecords?.count ?? 0) + "\n" + "Stopping further verify of Schedules..."
                    logerror(str: errorstring)
                    throw VerifyJSONError.verifyschedule
                }
                guard Equal().isequalstructs(rhs: plistschedules[i], lhs: transformedschedules[i]) == true else {
                    let errorstring = "Schedules in record " + String(i) + ": not equal..." + "\n" + "Stopping further verify of Schedules..."
                    logerror(str: errorstring)
                    throw VerifyJSONError.verifyschedule
                }
                for j in 0 ..< (plistschedules[i].logrecords?.count ?? 0) {
                    guard Equal().isequalstructs(rhs: plistschedules[i].logrecords?[j], lhs: transformedschedules[i].logrecords?[j]) == true else {
                        let errorstring = "Logrecord number " + String(j) + " in record " + String(i) + ": not equal..." + "\n" + "Stopping further verify of Schedules..."
                        logerror(str: errorstring)
                        throw VerifyJSONError.verifyschedule
                    }
                }
            }
        }
        logerror(str: "...verify of Schedules seems OK...")
    }

    func logerror(str: String) {
        let errormessage = OutputProcess()
        errormessage.addlinefromoutput(str: str)
        _ = Logfile(errormessage, true)
    }

    func verify() {
        do {
            try verifyconfigurations()
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }

        do {
            try verifyschedules()
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    init(profile: String?) {
        localprofile = profile
        validjsonhiddenID = Set()
        validplisthiddenID = Set()
        // Configurations
        readconfigurationsJSON()
        readconfigurationsplist()
        // Schedules
        readschedulesJSON()
        readschedulesplist()
        // veriy
        verify()
    }

    deinit {
        // print("deinit VerifyJSON")
    }
}

extension VerifyJSON: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
