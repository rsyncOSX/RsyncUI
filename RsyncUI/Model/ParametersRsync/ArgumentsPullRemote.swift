//
//  ArgumentsPullRemote.swift
//  RsyncUI
//

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsPullRemote {
    var config: SynchronizeConfiguration?

    func argumentspullremotewithparameters(dryRun: Bool, forDisplay: Bool, keepdelete: Bool) -> [String]? {
        if let config {
            let params = Params().params(config: config)
            let rsyncparameterssynchronize = RsyncParametersPullRemote(parameters: params)
            do {
                try rsyncparameterssynchronize.argumentsPullRemoteWithParameters(forDisplay: forDisplay,
                                                                                 verify: false,
                                                                                 dryrun: dryRun, keepDelete: keepdelete)
                return rsyncparameterssynchronize.computedArguments
            } catch {
                return nil
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        self.config = config
    }
}
