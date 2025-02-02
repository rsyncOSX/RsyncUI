//
//  ArgumentsSnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/08/2024.
//

// swiftlint:disable line_length

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsSnapshotRemoteCatalogs {
    var config: SynchronizeConfiguration?

    func remotefilelistarguments() -> [String]? {
        if let config {
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparametersrestore =
                    RsyncParametersRestore(parameters: parameters)
                rsyncparametersrestore.remoteargumentssnapshotcataloglist()
                return rsyncparametersrestore.computedarguments
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration) {
        guard config.task == SharedReference.shared.snapshot else { return }
        self.config = config
    }
}

// swiftlint:enable line_length
