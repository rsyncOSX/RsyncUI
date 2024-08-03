//
//  ArgumentsVerify.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsVerify: ComputeRsyncParameters {
    var config: SynchronizeConfiguration?

    func argumentsverify(forDisplay: Bool) -> [String]? {
        if let config {
            localCatalog = config.localCatalog
            remoteargs(config: config)
            setParameters1To6(config: config, forDisplay: forDisplay, verify: true)
            setParameters8To14(config: config, dryRun: true, forDisplay: forDisplay)
            switch config.task {
            case SharedReference.shared.synchronize:
                argumentsforsynchronize(forDisplay: forDisplay)
            case SharedReference.shared.snapshot:
                linkdestparameter(config: config, verify: true)
                argumentsforsynchronizesnapshot(forDisplay: forDisplay)
            case SharedReference.shared.syncremote:
                return []
            default:
                break
            }
            return arguments
        }
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        super.init()
        self.config = config
    }
}
