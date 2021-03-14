//
//  ObserveableReference.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 16/02/2021.
//
// swiftlint:disable function_body_length type_body_length

import Combine
import Foundation

class ObserveableReference: ObservableObject {
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
    // Environment
    @Published var environment: String = SharedReference.shared.environment ?? ""
    @Published var environmentvalue: String = SharedReference.shared.environmentvalue ?? ""
    // Paths for apps
    @Published var pathrsyncosx: String = SharedReference.shared.pathrsyncosx ?? ""
    @Published var pathrsyncosxsched: String = SharedReference.shared.pathrsyncosxsched ?? ""
    // Global SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    @Published var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var sshkeypathandidentityfile: String = ""
    // If local public sshkeys are present
    @Published var localsshkeys: Bool = SshKeys().validatepublickeypresent()
    // Check for network changes
    @Published var monitornetworkconnection: Bool = SharedReference.shared.monitornetworkconnection
    // Read configurations and schedules as JSON or not
    @Published var json: Bool = SharedReference.shared.json
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
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] rsyncpath in
                setandvalidatepathforrsync(rsyncpath)
            }.store(in: &subscriptions)
        $temporarypathforrestore
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
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
        $sshkeypathandidentityfile
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] identityfile in
                sshkeypathandidentiyfile(identityfile)
            }.store(in: &subscriptions)
        $sshport
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] port in
                sshport(port)
            }.store(in: &subscriptions)
        $json
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] json in
                SharedReference.shared.json = json
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
        $environment
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] environment in
                SharedReference.shared.environment = environment
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $environmentvalue
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] environmentvalue in
                SharedReference.shared.environmentvalue = environmentvalue
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $pathrsyncosx
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncosx in
                SharedReference.shared.pathrsyncosx = pathtorsyncosx
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $pathrsyncosxsched
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncosxsched in
                SharedReference.shared.pathrsyncosxsched = pathtorsyncosxsched
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }

    func setandvalidatepathforrsync(_ path: String) {
        guard inputchangedbyuser == true else { return }
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            let ok = try validate.validateandrsyncpath()
            if ok {
                isDirty = true
                return
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    func setandvalidapathforrestore(_ atpath: String) {
        guard inputchangedbyuser == true else { return }
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

    // SSH identityfile
    private func checksshkeypathbeforesaving(_ keypath: String) throws -> Bool {
        if keypath.first != "~" { throw SshError.noslash }
        let tempsshkeypath = keypath
        let sshkeypathandidentityfilesplit = tempsshkeypath.split(separator: "/")
        guard sshkeypathandidentityfilesplit.count > 2 else { throw SshError.noslash }
        guard sshkeypathandidentityfilesplit[1].count > 1 else { throw SshError.notvalidpath }
        guard sshkeypathandidentityfilesplit[2].count > 1 else { throw SshError.notvalidpath }
        return true
    }

    func sshkeypathandidentiyfile(_ keypath: String) {
        guard inputchangedbyuser == true else { return }
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            SharedReference.shared.sshkeypathandidentityfile = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                SharedReference.shared.sshkeypathandidentityfile = keypath
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    // SSH port number
    private func checksshport(_ port: String) throws -> Bool {
        guard port.isEmpty == false else { return false }
        if Int(port) != nil {
            return true
        } else {
            throw InputError.notvalidInt
        }
    }

    func sshport(_ port: String) {
        guard inputchangedbyuser == true else { return }
        // if port is empty set it to nil, e.g. default value
        guard port.isEmpty == false else {
            SharedReference.shared.sshport = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                SharedReference.shared.sshport = Int(port)
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
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

enum InputError: LocalizedError {
    case notvalidDouble
    case notvalidInt

    var errorDescription: String? {
        switch self {
        case .notvalidDouble:
            return NSLocalizedString("Not a valid number (Double)", comment: "ssh error") + "..."
        case .notvalidInt:
            return NSLocalizedString("Not a valid number (Int)", comment: "ssh error") + "..."
        }
    }
}

enum Validatedpath: LocalizedError {
    case nopath

    var errorDescription: String? {
        switch self {
        case .nopath:
            return NSLocalizedString("There is no such path", comment: "no path") + "..."
        }
    }
}
