//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//

/*
 .onAppear(perform: {
     if selectedprofile == nil {
         selectedprofile = SharedReference.shared.defaultprofile
     }
     // Initialize the Stateobject
     logrecords.update(profile: selectedprofile, validhiddenIDs: rsyncUIdata.rsyncdata?.validhiddenIDs)
 })
 */

import SwiftUI

struct Readlogsfromstore {
    var profile: String?
    var scheduleData: SchedulesSwiftUI

    init(profile: String? = nil, validhiddenIDs: Set<Int>? = nil) {
        self.profile = profile
        scheduleData = SchedulesSwiftUI(profile: self.profile, validhiddenIDs: validhiddenIDs ?? Set<Int>())
    }
}

final class RsyncUIlogrecords: ObservableObject {
    @Published var rsyncdata: Readlogsfromstore?
    var schedulesandlogs: [ConfigurationSchedule]?
    var profile: String?
    var alllogssorted: [Log]?

    func filterlogs(_ filter: String) -> [Log]? {
        // Important - must localize search in dates
        return alllogssorted?.filter {
            filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
        }
    }

    func filterlogsbyhiddenID(_ filter: String, _ hiddenID: Int) -> [Log]? {
        var joined: [Log]?
        guard hiddenID > -1 else { return nil }
        let schedulerecords = schedulesandlogs?.filter { $0.hiddenID == hiddenID }
        if (schedulerecords?.count ?? 0) > 0 {
            joined = [Log]()
            for i in 0 ..< (schedulerecords?.count ?? 0) {
                if let logrecords = schedulerecords?[i].logrecords {
                    joined?.append(contentsOf: logrecords)
                }
            }
            return joined?.sorted(by: \.date, using: >).filter {
                filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                    filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
            }
        }
        return nil
    }

    func filterlogsbyUUIDs(_ uuids: Set<UUID>) -> [Log]? {
        return alllogssorted?.filter { uuids.contains($0.id) }.sorted(by: \.date, using: >)
    }

    /*
     func hasactiveschedules(_ hiddenID: Int) -> Bool {
         let datestopnil = schedulesandlogs?.filter { $0.hiddenID == hiddenID &&
             $0.schedule != Scheduletype.manuel.rawValue &&
             $0.dateStop == nil
         }
         let datestartfuture = schedulesandlogs?.filter { $0.hiddenID == hiddenID &&
             $0.schedule != Scheduletype.manuel.rawValue &&
             $0.dateStart.en_us_date_from_string() > Date()
         }
         let datestopfuture = schedulesandlogs?.filter { $0.hiddenID == hiddenID &&
             $0.schedule != Scheduletype.manuel.rawValue &&
             $0.dateStop?.en_us_date_from_string() ?? Date() > Date()
         }

         return (datestopnil?.count ?? 0 > 0 ||
             datestartfuture?.count ?? 0 > 0 ||
             datestopfuture?.count ?? 0 > 0)
     }
     */

    func update(profile: String?, validhiddenIDs: Set<Int>?) {
        guard SharedReference.shared.reload == true else {
            SharedReference.shared.reload = true
            return
        }
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            rsyncdata = Readlogsfromstore(profile: nil, validhiddenIDs: validhiddenIDs)
        } else {
            rsyncdata = Readlogsfromstore(profile: profile, validhiddenIDs: validhiddenIDs)
        }
        schedulesandlogs = rsyncdata?.scheduleData.getschedules()
        alllogssorted = rsyncdata?.scheduleData.getalllogs()
    }

    init(profile _: String? = nil, validhiddenIDs _: Set<Int>? = nil) {
        guard SharedReference.shared.reload == true else {
            SharedReference.shared.reload = true
            return
        }
    }
}
