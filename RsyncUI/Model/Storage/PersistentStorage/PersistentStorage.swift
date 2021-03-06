//
//  PersistantStorage.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/11/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation

final class PersistentStorage {
    var configJSON: PersistentStorageConfigurationJSON?
    var scheduleJSON: PersistentStorageSchedulingJSON?
    var configPLIST: PersistentStorageConfigurationPLIST?
    var schedulePLIST: PersistentStorageSchedulingPLIST?
    var whattoreadorwrite: WhatToReadWrite?

    var configurations: [Configuration]?
    var schedules: [ConfigurationSchedule]?

    func convert(profile: String?) {
        if SharedReference.shared.json == false {
            if let profile = profile {
                _ = PersistentStorageConfigurationJSON(profile: profile,
                                                       readonly: false,
                                                       configurations: configurations)
                _ = PersistentStorageSchedulingJSON(profile: profile,
                                                    readonly: false,
                                                    schedules: schedules)
            } else {
                _ = PersistentStorageConfigurationJSON(profile: nil,
                                                       readonly: false,
                                                       configurations: configurations)
                _ = PersistentStorageSchedulingJSON(profile: nil,
                                                    readonly: false,
                                                    schedules: schedules)
            }
        } else {
            if let profile = profile {
                _ = PersistentStorageConfigurationPLIST(profile: profile,
                                                        readonly: false,
                                                        configurations: configurations)
                _ = PersistentStorageSchedulingPLIST(profile: profile,
                                                     readonly: false,
                                                     schedules: schedules)
            } else {
                _ = PersistentStorageConfigurationPLIST(profile: nil,
                                                        readonly: false,
                                                        configurations: configurations)
                _ = PersistentStorageSchedulingPLIST(profile: nil,
                                                     readonly: false,
                                                     schedules: schedules)
            }
        }
    }

    func saveMemoryToPersistentStore() {
        if SharedReference.shared.json {
            switch whattoreadorwrite {
            case .configuration:
                configJSON?.saveconfigInMemoryToPersistentStore()
            case .schedule:
                scheduleJSON?.savescheduleInMemoryToPersistentStore()
            default:
                return
            }
        } else {
            switch whattoreadorwrite {
            case .configuration:
                configPLIST?.saveconfigInMemoryToPersistentStore()
            case .schedule:
                schedulePLIST?.savescheduleInMemoryToPersistentStore()
            default:
                return
            }
        }
    }

    init(profile: String?,
         whattoreadorwrite: WhatToReadWrite,
         readonly: Bool,
         configurations: [Configuration]?,
         schedules: [ConfigurationSchedule]?)
    {
        self.whattoreadorwrite = whattoreadorwrite
        self.configurations = configurations
        self.schedules = schedules

        if SharedReference.shared.json {
            switch whattoreadorwrite {
            case .configuration:
                configJSON = PersistentStorageConfigurationJSON(profile: profile,
                                                                readonly: readonly,
                                                                configurations: self.configurations)
            case .schedule:
                scheduleJSON = PersistentStorageSchedulingJSON(profile: profile,
                                                               readonly: readonly,
                                                               schedules: self.schedules)
            default:
                return
            }
        } else {
            switch whattoreadorwrite {
            case .configuration:
                configPLIST = PersistentStorageConfigurationPLIST(profile: profile,
                                                                  readonly: readonly,
                                                                  configurations: self.configurations)
            case .schedule:
                schedulePLIST = PersistentStorageSchedulingPLIST(profile: profile,
                                                                 readonly: readonly,
                                                                 schedules: self.schedules)
            default:
                return
            }
        }
    }

    init(profile: String?,
         whattoreadorwrite: WhatToReadWrite)
    {
        self.whattoreadorwrite = whattoreadorwrite
        if SharedReference.shared.json {
            switch whattoreadorwrite {
            case .configuration:
                configJSON = PersistentStorageConfigurationJSON(profile: profile)
            case .schedule:
                scheduleJSON = PersistentStorageSchedulingJSON(profile: profile)
            default:
                return
            }
        } else {
            switch whattoreadorwrite {
            case .configuration:
                configPLIST = PersistentStorageConfigurationPLIST(profile: profile)
            case .schedule:
                schedulePLIST = PersistentStorageSchedulingPLIST(profile: profile)
            default:
                return
            }
        }
    }

    init() {}

    deinit {
        // print("deinit PersistentStorage")
        print(self.whattoreadorwrite)
        self.configJSON = nil
        self.configPLIST = nil
        self.scheduleJSON = nil
        self.schedulePLIST = nil
    }
}
