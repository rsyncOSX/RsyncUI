//
//  ObserveableReferenceAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint:disable function_body_length

import Combine
import Files
import Foundation

enum CannotUpdateSnaphotsError: LocalizedError {
    case cannotupdate

    var errorDescription: String? {
        switch self {
        case .cannotupdate:
            return NSLocalizedString("Only synchronize ID can be changed on a Snapshot task", comment: "cannot") + "..."
        }
    }
}

final class ObserveableAddConfigurations: ObservableObject {
    @Published var localcatalog: String = ""
    @Published var remotecatalog: String = ""
    @Published var donotaddtrailingslash: Bool = false
    @Published var remoteuser: String = ""
    @Published var remoteserver: String = ""
    @Published var backupID: String = ""
    @Published var selectedconfig: Configuration?
    @Published var selectedrsynccommand = TypeofTask.synchronize

    @Published var newprofile: String = ""
    @Published var selectedprofile: String?
    @Published var deletedefaultprofile: Bool = false

    @Published var deleted: Bool = false
    @Published var added: Bool = false
    @Published var updated: Bool = false
    @Published var created: Bool = false
    @Published var reload: Bool = false
    @Published var confirmdeleteselectedprofile: Bool = false
    @Published var showAlertfordelete: Bool = false

    @Published var inputchangedbyuser: Bool = false
    @Published var isDirty: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()
    // Set true if remote storage is a local attached Volume
    var remotestorageislocal: Bool = false

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $donotaddtrailingslash
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $localcatalog
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $remotecatalog
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
                remotestorageislocal = verifyremotestorageislocal()
            }.store(in: &subscriptions)
        $remoteuser
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $remoteserver
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $backupID
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $selectedrsynccommand
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $newprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $selectedprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $deletedefaultprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $confirmdeleteselectedprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $showAlertfordelete
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $selectedconfig
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }

    func addconfig(_ profile: String?, _ configurations: [Configuration]?) {
        let getdata = AppendConfig(selectedrsynccommand.rawValue,
                                   localcatalog,
                                   remotecatalog,
                                   donotaddtrailingslash,
                                   remoteuser,
                                   remoteserver,
                                   backupID,
                                   // add post and pretask in it own view, set nil here
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil)
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            let updateconfigurations =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            if updateconfigurations.addconfiguration(newconfig) == true {
                reload = true
                added = true
                resetform()
            }
        }
    }

    func updateconfig(_ profile: String?, _ configurations: [Configuration]?) {
        let updateddata = AppendConfig(selectedrsynccommand.rawValue,
                                       localcatalog,
                                       remotecatalog,
                                       donotaddtrailingslash,
                                       remoteuser,
                                       remoteserver,
                                       backupID,
                                       // add post and pretask in it own view, set nil here
                                       nil,
                                       nil,
                                       nil,
                                       nil,
                                       nil,
                                       selectedconfig?.hiddenID ?? -1)
        if let updatedconfig = VerifyConfiguration().verify(updateddata) {
            let updateconfiguration =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            updateconfiguration.updateconfiguration(updatedconfig, false)
            reload = true
            updated = true
            resetform()
        }
    }

    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        donotaddtrailingslash = false
        remoteuser = ""
        remoteserver = ""
        backupID = ""
        selectedconfig = nil
    }

    func createprofile() {
        guard newprofile.isEmpty == false else { return }
        let catalogprofile = CatalogProfile()
        catalogprofile.createprofilecatalog(profile: newprofile)
        selectedprofile = newprofile
        created = true
        newprofile = ""
    }

    func deleteprofile(_ profile: String?) {
        guard confirmdeleteselectedprofile == true else { return }
        if let profile = profile {
            guard profile != NSLocalizedString("Default profile", comment: "default profile") else {
                deletedefaultprofile = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                    deletedefaultprofile = false
                }
                return
            }
            CatalogProfile().deleteprofilecatalog(profileName: profile)
            selectedprofile = nil
            deleted = true
        } else {
            deletedefaultprofile = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                deletedefaultprofile = false
            }
        }
    }

    func validateandupdate(_ profile: String?, _ configurations: [Configuration]?) {
        // Validate not a snapshot task
        do {
            let validated = try validatenotsnapshottask()
            if validated {
                updateconfig(profile, configurations)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    func updateview() {
        if let config = selectedconfig {
            localcatalog = config.localCatalog
            remotecatalog = config.offsiteCatalog
            remoteuser = config.offsiteUsername
            remoteserver = config.offsiteServer
            backupID = config.backupID
        } else {
            localcatalog = ""
            remotecatalog = ""
            remoteuser = ""
            remoteserver = ""
            backupID = ""
        }
    }

    private func validatenotsnapshottask() throws -> Bool {
        if let config = selectedconfig {
            if config.task == SharedReference.shared.snapshot {
                throw CannotUpdateSnaphotsError.cannotupdate
            } else {
                return true
            }
        }
        return false
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }

    func verifyremotestorageislocal() -> Bool {
        do {
            try Folder(path: remotecatalog)
            return true
        } catch {
            return false
        }
    }
}

/*
 TODO:
 - fix that ID can be changed on snapshot tasks.
 */
