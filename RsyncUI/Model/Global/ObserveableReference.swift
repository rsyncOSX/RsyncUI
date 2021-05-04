//
//  ObserveableReference.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 16/02/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation

final class ObserveableReference: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
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
    @Published var inputchangedbyuser: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $rsyncversion3
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] rsyncver3 in
                SharedReference.shared.rsyncversion3 = rsyncver3
                isDirty = inputchangedbyuser
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
            .sink { [unowned self] value in
                SharedReference.shared.nologging = value
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $minimumlogging
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] min in
                SharedReference.shared.minimumlogging = min
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $fulllogging
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] full in
                SharedReference.shared.fulllogging = full
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $detailedlogging
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] detailed in
                SharedReference.shared.detailedlogging = detailed
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $monitornetworkconnection
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] monitor in
                SharedReference.shared.monitornetworkconnection = monitor
                isDirty = inputchangedbyuser
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
            .sink { [unowned self] pathtorsyncosx in
                SharedReference.shared.pathrsyncui = pathtorsyncosx
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $pathrsyncschedule
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncosxsched in
                SharedReference.shared.pathrsyncschedule = pathtorsyncosxsched
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }
}

extension ObserveableReference {
    // Only validate path if rsyncver3 is true
    func setandvalidatepathforrsync(_ path: String) { guard inputchangedbyuser == true else { return }
        guard path.isEmpty == false, rsyncversion3 == true else {
            isDirty = true
            // Set rsync path = nil
            let validate = SetandValidatepathforrsync()
            validate.setlocalrsyncpath("")
            return
        }
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            let ok = try validate.validateandrsyncpath()
            if ok {
                isDirty = true
                return
            }
        } catch let e {
            // Default back to default values of rsync
            setdefaultvaulesrsync()
            let error = e
            self.propogateerror(error: error)
        }
    }

    // Set default version 2 of rsync values
    private func setdefaultvaulesrsync() {
        let validate = SetandValidatepathforrsync()
        validate.setdefaultvaluesver2rsync()
        rsyncversion3 = false
        localrsyncpath = ""
        isDirty = true
    }

    func setandvalidapathforrestore(_ atpath: String) {
        guard inputchangedbyuser == true else { return }
        guard atpath.isEmpty == false else {
            // Delete path
            isDirty = true
            SharedReference.shared.pathforrestore = nil
            return
        }
        do {
            let ok = try validatepath(atpath)
            if ok {
                isDirty = true
                SharedReference.shared.pathforrestore = atpath
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
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
        guard inputchangedbyuser == true else { return }
        do {
            let verified = try checkmarkdays(days)
            if verified {
                SharedReference.shared.marknumberofdayssince = Double(days) ?? 5
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }
}

extension ObserveableReference: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum Validatedpath: LocalizedError {
    case nopath

    var errorDescription: String? {
        switch self {
        case .nopath:
            return NSLocalizedString("No such path", comment: "no path") + "..."
        }
    }
}

/*
 TODO:
 -  QA of setting path for rsync
 - QA of setting path for restore and delete path for restore
 */
