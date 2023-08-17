//
//  ObservablePreandPostTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//

import Foundation
import Observation

@Observable
final class ObservablePreandPostTask {
    var enablepre: Bool = false
    var enablepost: Bool = false
    var pretask: String = ""
    var posttask: String = ""
    var haltshelltasksonerror: Bool = false
    var reload: Bool = false
    var selectedconfig: Configuration?
    // alert about error
    var error: Error = InputError.noerror
    var alerterror: Bool = false

    func updateconfig(_ profile: String?, _ configurations: [Configuration]?) {
        // Append default config data to the update,
        // only post and pretask is new
        let updateddata = AppendTask(selectedconfig?.task ?? "",
                                     selectedconfig?.localCatalog ?? "",
                                     selectedconfig?.offsiteCatalog ?? "",
                                     false,
                                     selectedconfig?.offsiteUsername,
                                     selectedconfig?.offsiteServer,
                                     selectedconfig?.backupID,
                                     enablepre,
                                     pretask,
                                     enablepost,
                                     posttask,
                                     haltshelltasksonerror,
                                     selectedconfig?.hiddenID ?? -1)
        if let updatedconfig = VerifyConfiguration().verify(updateddata) {
            let updateconfiguration =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            updateconfiguration.updateconfiguration(updatedconfig, false)
            reload = true
            // updated = true
            resetform()
        }
    }

    func resetform() {
        enablepre = false
        pretask = ""
        enablepost = false
        posttask = ""
        haltshelltasksonerror = false
        selectedconfig = nil
    }

    func validateandupdate(_ profile: String?, _ configurations: [Configuration]?) {
        // Validate not a snapshot task
        do {
            let validated = try validatenotsnapshottask()
            if validated {
                updateconfig(profile, configurations)
            }
        } catch let e {
            error = e
            alerterror = true
        }
    }

    func updateview(_ config: Configuration?) {
        selectedconfig = config
        if let config = selectedconfig {
            // pre task
            pretask = config.pretask ?? ""
            if config.pretask != nil {
                if config.executepretask == 1 {
                    enablepre = true
                } else {
                    enablepre = false
                }
            } else {
                enablepre = false
            }

            // post task
            posttask = config.posttask ?? ""
            if config.posttask != nil {
                if config.executeposttask == 1 {
                    enablepost = true
                } else {
                    enablepost = false
                }
            } else {
                enablepost = false
            }

            if config.posttask != nil {
                if config.haltshelltasksonerror == 1 {
                    haltshelltasksonerror = true
                } else {
                    haltshelltasksonerror = false
                }
            } else {
                haltshelltasksonerror = false
            }
        } else {
            resetform()
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
}
