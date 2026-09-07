//
//  ArgumentsRestore.swift
//  RsyncUI
//

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsRestore {
    var config: SynchronizeConfiguration?
    var restoresnapshotbyfiles: Bool = false
    private let destination: String?

    func argumentsrestore(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            let params = Params().params(config: config, restorePath: destination)
            let rsyncparametersrestore = RsyncParametersRestore(parameters: params)
            do {
                try rsyncparametersrestore.argumentsRestore(forDisplay: forDisplay,
                                                            verify: false,
                                                            dryrun: dryRun,
                                                            restoreSnapshotByFiles: restoresnapshotbyfiles)
                return rsyncparametersrestore.computedArguments
            } catch {
                return nil
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?, restoresnapshotbyfiles: Bool, destination: String? = nil) {
        self.destination = destination
        self.config = config
        self.restoresnapshotbyfiles = restoresnapshotbyfiles
    }
}
