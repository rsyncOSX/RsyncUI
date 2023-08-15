//
//  ObservablePreandPostTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//

import Combine
import Foundation

@MainActor
final class ObservablePreandPostTask: ObservableObject {
    @Published var enablepre: Bool = false
    @Published var enablepost: Bool = false
    @Published var pretask: String = ""
    @Published var posttask: String = ""
    @Published var haltshelltasksonerror: Bool = false
    // Added and updated labels
    // @Published var updated = false
    @Published var reload: Bool = false
    // Alerts
    @Published var alerterror: Bool = false
    @Published var error: Error = Validatedpath.noerror

    // Combine
    var subscriptions = Set<AnyCancellable>()
    var selectedconfig: Configuration?

    init() {
        $enablepre
            .sink { _ in
            }.store(in: &subscriptions)
        $enablepost
            .sink { _ in
            }.store(in: &subscriptions)
        $pretask
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $posttask
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $haltshelltasksonerror
            .sink { _ in
            }.store(in: &subscriptions)
    }

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
