//
//  ObserveableReferenceAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//

import Combine
import Foundation

final class ObserveableReferenceAddConfigurations: ObservableObject {
    private var localconfigurations: [Configuration]?
    private var localeprofile: String?

    @Published var localcatalog: String = ""
    @Published var remotecatalog: String = ""
    @Published var donotaddtrailingslash: Bool = false
    @Published var remoteuser: String = ""
    @Published var remoteserver: String = ""
    @Published var backupID: String = ""
    @Published var selectedconfig: Configuration? = nil
    @Published var selectedrsynccommand = TypeofTask.synchronize

    @Published var newprofile: String = ""
    @Published var selectedprofile: String? = nil
    @Published var deletedefaultprofile: Bool = false

    @Published var deleted: Bool = false
    @Published var added: Bool = false
    @Published var updated: Bool = false
    @Published var created: Bool = false
    @Published var reload: Bool = false
    @Published var confirmdeleteselectedprofile: Bool = false

    @Published var inputchangedbyuser: Bool = false
    @Published var isDirty: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init(profile: String?, configurations: [Configuration]?) {
        localconfigurations = configurations
        localeprofile = profile

        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $donotaddtrailingslash
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] donotaddtrailingslash in
                print(donotaddtrailingslash)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }

    func addconfig() {
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
                UpdateConfigurations(profile: localeprofile,
                                     configurations: localconfigurations)
            if updateconfigurations.addconfiguration(newconfig) == true {
                reload = true
                added = true
                // Show added for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                    added = false
                    resetform()
                }
            }
        }
    }

    func updateconfig() {
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
                UpdateConfigurations(profile: localeprofile,
                                     configurations: localconfigurations)
            updateconfiguration.updateconfiguration(updatedconfig, false)
            reload = true
            updated = true
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                self.updated = false
                resetform()
            }
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
        let existingprofiles = catalogprofile.getcatalogsasstringnames()
        guard existingprofiles?.contains(newprofile) == false else { return }
        _ = catalogprofile.createprofilecatalog(profile: newprofile)
        selectedprofile = newprofile
        created = true
        newprofile = ""
        // profilenames.update()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            self.created = false
            resetform()
        }
    }

    func deleteprofile() {
        guard confirmdeleteselectedprofile == true else { return }
        if let profile = localeprofile {
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
            // profilenames.update()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                deleted = false
            }
        } else {
            deletedefaultprofile = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                deletedefaultprofile = false
            }
        }
    }

    func validateandupdate() {
        // Validate not a snapshot task
        do {
            let validated = try validatenotsnapshottask()
            if validated {
                updateconfig()
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
}
