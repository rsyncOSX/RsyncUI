//
//  ArgumentsSnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/08/2024.
//

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsSnapshotRemoteCatalogs {
    var config: SynchronizeConfiguration?

    func remotefilelistarguments() -> [String]? {
        if let config {
            let params = Params().params(config: config)
            let rsyncparametersrestore = RsyncParametersRestore(parameters: params)
            do {
                try rsyncparametersrestore.remoteArgumentsSnapshotCatalogList()
                return rsyncparametersrestore.computedArguments
            } catch {
                return nil
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration) {
        guard config.task == SharedReference.shared.snapshot else { return }
        self.config = config
    }
}
