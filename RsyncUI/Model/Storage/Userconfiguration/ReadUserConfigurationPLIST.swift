//
//  ReadUserConfigurationPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/05/2021.
//
// swiftlint:disable line_length cyclomatic_complexity function_body_length

import Combine
import Foundation

final class ReadUserConfigurationPLIST: NamesandPaths {
    var filenamedatastore = [SharedReference.shared.userconfigplist]
    var subscriptons = Set<AnyCancellable>()

    private func setuserconfiguration(_ dict: NSDictionary?) {
        if let dict = dict {
            SharedReference.shared.inloading = true
            // Another version of rsync
            if let version3rsync = dict.value(forKey: DictionaryStrings.version3Rsync.rawValue) as? Int {
                if version3rsync == 1 {
                    SharedReference.shared.rsyncversion3 = true
                } else {
                    SharedReference.shared.rsyncversion3 = false
                }
            }
            // Detailed logging
            if let detailedlogging = dict.value(forKey: DictionaryStrings.detailedlogging.rawValue) as? Int {
                if detailedlogging == 1 {
                    SharedReference.shared.detailedlogging = true
                } else {
                    SharedReference.shared.detailedlogging = false
                }
            }
            // Optional path for rsync
            if let rsyncPath = dict.value(forKey: DictionaryStrings.rsyncPath.rawValue) as? String {
                SharedReference.shared.localrsyncpath = rsyncPath
                validatepathforrsync(rsyncPath)
            }
            // Temporary path for restores single files or directory
            if let restorePath = dict.value(forKey: DictionaryStrings.restorePath.rawValue) as? String {
                if restorePath.count > 0 {
                    SharedReference.shared.pathforrestore = restorePath
                } else {
                    SharedReference.shared.pathforrestore = nil
                }
            }
            // Mark tasks
            if let marknumberofdayssince = dict.value(forKey: DictionaryStrings.marknumberofdayssince.rawValue) as? String {
                if Double(marknumberofdayssince) ?? 0 > 0 {
                    SharedReference.shared.marknumberofdayssince = Double(marknumberofdayssince)!
                }
            }
            // Paths rsyncUI and RsyncSchedule
            if let pathrsyncui = dict.value(forKey: DictionaryStrings.pathrsyncui.rawValue) as? String {
                if pathrsyncui.isEmpty == true {
                    SharedReference.shared.pathrsyncui = nil
                } else {
                    SharedReference.shared.pathrsyncui = pathrsyncui
                }
            }
            if let pathrsyncschedule = dict.value(forKey: DictionaryStrings.pathrsyncschedule.rawValue) as? String {
                if pathrsyncschedule.isEmpty == true {
                    SharedReference.shared.pathrsyncschedule = nil
                } else {
                    SharedReference.shared.pathrsyncschedule = pathrsyncschedule
                }
            }
            // No logging, minimum logging or full logging
            if let minimumlogging = dict.value(forKey: DictionaryStrings.minimumlogging.rawValue) as? Int {
                if minimumlogging == 1 {
                    SharedReference.shared.minimumlogging = true
                } else {
                    SharedReference.shared.minimumlogging = false
                }
            }
            if let fulllogging = dict.value(forKey: DictionaryStrings.fulllogging.rawValue) as? Int {
                if fulllogging == 1 {
                    SharedReference.shared.fulllogging = true
                } else {
                    SharedReference.shared.fulllogging = false
                }
            }
            // To set correct toggle in user configuration
            if SharedReference.shared.fulllogging == false && SharedReference.shared.minimumlogging == false {
                SharedReference.shared.nologging = true
            } else {
                SharedReference.shared.nologging = false
            }

            if let environment = dict.value(forKey: DictionaryStrings.environment.rawValue) as? String {
                SharedReference.shared.environment = environment
            }
            if let environmentvalue = dict.value(forKey: DictionaryStrings.environmentvalue.rawValue) as? String {
                SharedReference.shared.environmentvalue = environmentvalue
            }
            if let sshkeypathandidentityfile = dict.value(forKey: DictionaryStrings.sshkeypathandidentityfile.rawValue) as? String {
                SharedReference.shared.sshkeypathandidentityfile = sshkeypathandidentityfile
            }
            if let sshport = dict.value(forKey: DictionaryStrings.sshport.rawValue) as? Int {
                SharedReference.shared.sshport = sshport
            }
            if let monitornetworkconnection = dict.value(forKey: DictionaryStrings.monitornetworkconnection.rawValue) as? Int {
                if monitornetworkconnection == 1 {
                    SharedReference.shared.monitornetworkconnection = true
                } else {
                    SharedReference.shared.monitornetworkconnection = false
                }
            }
            SharedReference.shared.inloading = false
        }
    }

    func validatepathforrsync(_ path: String) {
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            let ok = try validate.validateandrsyncpath()
            if ok { return }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    @discardableResult
    init() {
        super.init(.configurations)
        filenamedatastore.publisher
            .compactMap { name -> URL? in
                URL(fileURLWithPath: (fullpathmacserial ?? "") + name)
            }
            .tryMap { url -> NSDictionary in
                try NSDictionary(contentsOf: url, error: ())
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    /*
                     case let .failure(error):
                         self.propogateerror(error: error)
                     */
                    return
                }
            }, receiveValue: { [unowned self] data in
                if let items = data.object(forKey: SharedReference.shared.userconfigkey) as? NSArray {
                    let userconfig = items.map { row -> NSDictionary? in
                        switch row {
                        case is NSNull:
                            return nil
                        case let value as NSDictionary:
                            return value
                        default:
                            return nil
                        }
                    }
                    guard userconfig.count > 0 else { return }
                    setuserconfiguration(userconfig[0])
                }
                subscriptons.removeAll()
            }).store(in: &subscriptons)
    }
}
