//
//  RsyncUIconfigurations.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class RsyncUIconfigurations {
    var configurations: [SynchronizeConfiguration]?
    var profile: String?
    @ObservationIgnored var validhiddenIDs: Set<Int>?

    func resetandupdatevalidhiddenIDS() {
        if validhiddenIDs == nil {
            validhiddenIDs = Set<Int>()
        } else {
            validhiddenIDs?.removeAll()
        }
        for i in 0 ..< (configurations?.count ?? 0) {
            validhiddenIDs?.insert(configurations?[i].hiddenID ?? -1)
        }
    }

    /*
     func getuniqueserversandlogins() -> [UniqueserversandLogins]? {
         let configs = configurations?.filter {
             SharedReference.shared.synctasks.contains($0.task)
         }
         guard configs?.count ?? 0 > 0 else { return nil }
         var uniqueserversandlogins = [UniqueserversandLogins]()
         for i in 0 ..< (configs?.count ?? 0) {
             if let config = configs?[i] {
                 if config.offsiteUsername.isEmpty == false, config.offsiteServer.isEmpty == false {
                     let record = UniqueserversandLogins(config.offsiteUsername, config.offsiteServer)
                     if uniqueserversandlogins.filter({ ($0.offsiteUsername == record.offsiteUsername) &&
                             ($0.offsiteServer == record.offsiteServer)
                     }).count == 0 {
                         uniqueserversandlogins.append(record)
                     }
                 }
             }
         }
         return uniqueserversandlogins
     }
     */
    init(_ profile: String?,
         _ configurationsfromstore: [SynchronizeConfiguration]?,
         _ validehiddenIDsfromstore: Set<Int>?)
    {
        self.profile = profile
        configurations = configurationsfromstore
        validhiddenIDs = validehiddenIDsfromstore
    }
}
