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
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparametersrestore =
                    RsyncParametersRestore(parameters: parameters)
                if config.task == SharedReference.shared.synchronize {
                    rsyncparametersrestore.remoteargumentsfilelist()
                } else if config.task == SharedReference.shared.snapshot {
                    rsyncparametersrestore.remoteargumentssnapshotfilelist()
                }
                return rsyncparametersrestore.computedarguments
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration) {
        self.config = config
    }
}

// swiftlint:enable line_length
