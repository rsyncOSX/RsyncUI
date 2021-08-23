//
//  ObserveableReference.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 16/02/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation

final class ObserveableUsersetting: ObservableObject {
    // True if version 3.1.2 or 3.1.3 of rsync in /usr/local/bin
    @Published var rsyncversion3: Bool = SharedReference.shared.rsyncversion3
    // Optional path to rsync, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var localrsyncpath: String = ""
    // No valid rsyncPath - true if no valid rsync is found
    @Published var norsync: Bool = false
    // Temporary path for restore, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var temporarypathforrestore: String = ""
    // Detailed logging
    @Published var detailedlogging: Bool = SharedReference.shared.detailedlogging
    // Logging to logfile
    @Published var minimumlogging: Bool = SharedReference.shared.minimumlogging
    @Published var fulllogging: Bool = SharedReference.shared.fulllogging
    @Published var nologging: Bool = SharedReference.shared.nologging
    // Mark number of days since last backup
    @Published var marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
    // Paths for apps
    @Published var pathrsyncui: String = SharedReference.shared.pathrsyncui ?? ""
    @Published var pathrsyncschedule: String = SharedReference.shared.pathrsyncschedule ?? ""
    // Check for network changes
    @Published var monitornetworkconnection: Bool = SharedReference.shared.monitornetworkconnection
    // Check input when loading schedules and adding config
    @Published var checkinput: Bool = SharedReference.shared.checkinput
    // Value to check if input field is changed by user
    // @Published var inputchangedbyuser: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        /*
         $inputchangedbyuser
             .sink { _ in
             }.store(in: &subscriptions)
          */
        $rsyncversion3
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { rsyncver3 in
                SharedReference.shared.rsyncversion3 = rsyncver3
            }.store(in: &subscriptions)
        $localrsyncpath
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] rsyncpath in
                setandvalidatepathforrsync(rsyncpath)
            }.store(in: &subscriptions)
        $temporarypathforrestore
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] restorepath in
                setandvalidapathforrestore(restorepath)
            }.store(in: &subscriptions)
        $nologging
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { value in
                SharedReference.shared.nologging = value
            }.store(in: &subscriptions)
        $minimumlogging
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { min in
                SharedReference.shared.minimumlogging = min
            }.store(in: &subscriptions)
        $fulllogging
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { full in
                SharedReference.shared.fulllogging = full
            }.store(in: &subscriptions)
        $detailedlogging
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { detailed in
                SharedReference.shared.detailedlogging = detailed
            }.store(in: &subscriptions)
        $monitornetworkconnection
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { monitor in
                SharedReference.shared.monitornetworkconnection = monitor
            }.store(in: &subscriptions)
        $checkinput
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { check in
                SharedReference.shared.checkinput = check
            }.store(in: &subscriptions)
        $marknumberofdayssince
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] value in
                markdays(days: value)
            }.store(in: &subscriptions)
        $pathrsyncui
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { pathtorsyncosx in
                SharedReference.shared.pathrsyncui = pathtorsyncosx
            }.store(in: &subscriptions)
        $pathrsyncschedule
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { pathtorsyncosxsched in
                SharedReference.shared.pathrsyncschedule = pathtorsyncosxsched
            }.store(in: &subscriptions)
    }
}

extension ObserveableUsersetting {
    // Only validate path if rsyncver3 is true
    func setandvalidatepathforrsync(_ path: String) {
        guard path.isEmpty == false, rsyncversion3 == true else {
            // Set rsync path = nil
            let validate = SetandValidatepathforrsync()
            validate.setlocalrsyncpath("")
            return
        }
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            _ = try validate.validateandrsyncpath()
        } catch let e {
            // Default back to default values of rsync
            setdefaultvaulesrsync()
            let error = e
            propogateerror(error: error)
        }
    }

    // Set default version 2 of rsync values
    private func setdefaultvaulesrsync() {
        let validate = SetandValidatepathforrsync()
        validate.setdefaultvaluesver2rsync()
        rsyncversion3 = false
        localrsyncpath = ""
    }

    func setandvalidapathforrestore(_ atpath: String) {
        guard atpath.isEmpty == false else {
            // Delete path
            SharedReference.shared.pathforrestore = nil
            return
        }
        do {
            let ok = try validatepath(atpath)
            if ok {
                SharedReference.shared.pathforrestore = atpath
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    // Mark days
    private func checkmarkdays(_ days: String) throws -> Bool {
        guard days.isEmpty == false else { return false }
        if Double(days) != nil {
            return true
        } else {
            throw InputError.notvalidDouble
        }
    }

    func markdays(days: String) {
        do {
            let verified = try checkmarkdays(days)
            if verified {
                SharedReference.shared.marknumberofdayssince = Double(days) ?? 5
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }
}

extension ObserveableUsersetting: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum Validatedpath: LocalizedError {
    case nopath

    var errorDescription: String? {
        switch self {
        case .nopath:
            return "No such path"
        }
    }
}
