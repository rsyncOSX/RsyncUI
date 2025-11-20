//
//  ArgumentsRemoteFileList.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/08/2024.
//
// swiftlint:disable line_length

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsRemoteFileList {
    var config: SynchronizeConfiguration?

    func remotefilelistarguments() -> [String]? {
        if let config {
            let params = Params().params(config: config)
            let rsyncparametersremotelist = RsyncParametersRestore(parameters: params)
            if config.task == SharedReference.shared.synchronize {
                do {
                    try rsyncparametersremotelist.remoteArgumentsFileList()
                    return rsyncparametersremotelist.computedArguments
                } catch {}
            } else if config.task == SharedReference.shared.snapshot {
                do {
                    try rsyncparametersremotelist.remoteArgumentsSnapshotFileList()
                    return rsyncparametersremotelist.computedArguments
                } catch {}
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration) {
        self.config = config
    }
}

// swiftlint:enable line_length
