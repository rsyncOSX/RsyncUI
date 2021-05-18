//
//  WriteUserConfigurationPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/05/2021.
//
// swiftlint:disable line_length function_body_length cyclomatic_complexity

import Foundation

final class WriteUserConfigurationPLIST: NamesandPaths {
    private func convertuserconfiguration() -> [NSMutableDictionary]? {
        var version3Rsync: Int?
        var detailedlogging: Int?
        var minimumlogging: Int?
        var fulllogging: Int?
        var marknumberofdayssince: String?
        var monitornetworkconnection: Int?

        if SharedReference.shared.rsyncversion3 {
            version3Rsync = 1
        } else {
            version3Rsync = 0
        }
        if SharedReference.shared.detailedlogging {
            detailedlogging = 1
        } else {
            detailedlogging = 0
        }
        if SharedReference.shared.minimumlogging {
            minimumlogging = 1
        } else {
            minimumlogging = 0
        }
        if SharedReference.shared.fulllogging {
            fulllogging = 1
        } else {
            fulllogging = 0
        }
        if SharedReference.shared.monitornetworkconnection {
            monitornetworkconnection = 1
        } else {
            monitornetworkconnection = 0
        }
        marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
        let dict: NSMutableDictionary = [
            DictionaryStrings.version3Rsync.rawValue: version3Rsync ?? 0 as Int,
            DictionaryStrings.detailedlogging.rawValue: detailedlogging ?? 0 as Int,
            DictionaryStrings.minimumlogging.rawValue: minimumlogging ?? 0 as Int,
            DictionaryStrings.fulllogging.rawValue: fulllogging ?? 0 as Int,
            DictionaryStrings.marknumberofdayssince.rawValue: marknumberofdayssince ?? "5.0",
            DictionaryStrings.monitornetworkconnection.rawValue: monitornetworkconnection ?? 0 as Int,
        ]
        if let rsyncpath = SharedReference.shared.localrsyncpath {
            dict.setObject(rsyncpath, forKey: DictionaryStrings.rsyncPath.rawValue as NSCopying)
        }
        if let restorepath = SharedReference.shared.pathforrestore {
            dict.setObject(restorepath, forKey: DictionaryStrings.restorePath.rawValue as NSCopying)
        } else {
            dict.setObject("", forKey: DictionaryStrings.restorePath.rawValue as NSCopying)
        }
        if let pathrsyncui = SharedReference.shared.pathrsyncui {
            if pathrsyncui.isEmpty == false {
                dict.setObject(pathrsyncui, forKey: DictionaryStrings.pathrsyncui.rawValue as NSCopying)
            }
        }
        if let pathrsyncschedule = SharedReference.shared.pathrsyncschedule {
            if pathrsyncschedule.isEmpty == false {
                dict.setObject(pathrsyncschedule, forKey: DictionaryStrings.pathrsyncschedule.rawValue as NSCopying)
            }
        }
        if let environment = SharedReference.shared.environment {
            if environment.isEmpty == false {
                dict.setObject(environment, forKey: DictionaryStrings.environment.rawValue as NSCopying)
            }
        }
        if let environmentvalue = SharedReference.shared.environmentvalue {
            if environmentvalue.isEmpty == false {
                dict.setObject(environmentvalue, forKey: DictionaryStrings.environmentvalue.rawValue as NSCopying)
            }
        }
        if let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            if sshkeypathandidentityfile.isEmpty == false {
                dict.setObject(sshkeypathandidentityfile, forKey: DictionaryStrings.sshkeypathandidentityfile.rawValue as NSCopying)
            }
        }
        if let sshport = SharedReference.shared.sshport {
            dict.setObject(sshport, forKey: DictionaryStrings.sshport.rawValue as NSCopying)
        }
        var array = [NSMutableDictionary]()
        array.append(dict)
        return array
    }

    @discardableResult
    func writeNSDictionaryToPersistentStorage(_ data: [NSDictionary]?) -> Bool {
        if let data = data,
           let fullroot = fullpathmacserial
        {
            let dictionary = NSDictionary(object: data, forKey: SharedReference.shared.userconfigkey as NSCopying)
            let write = dictionary.write(toFile: fullroot + SharedReference.shared.userconfigplist,
                                         atomically: true)
            if write && SharedReference.shared.menuappisrunning {
                Notifications().showNotification("Sending reload message to menu app")
                DistributedNotificationCenter.default()
                    .postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring),
                                          object: nil, deliverImmediately: true)
            }
            return write
        }
        return false
    }

    init() {
        super.init(.configurations)
        let userconfig = convertuserconfiguration()
        writeNSDictionaryToPersistentStorage(userconfig)
    }
}
