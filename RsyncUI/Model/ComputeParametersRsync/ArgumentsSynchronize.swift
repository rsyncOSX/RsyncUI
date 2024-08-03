//
//  ArgumentsSynchronize.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsSynchronize: ComputeRsyncParameters {
    var config: SynchronizeConfiguration?

    func argumentssynchronize(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            localCatalog = config.localCatalog
            if self.config?.task == SharedReference.shared.syncremote {
                remoteargssyncremote(config: config)
            } else {
                remoteargs(config: config)
            }
            setParameters1To6(config: config, dryRun: dryRun, forDisplay: forDisplay, verify: false)
            setParameters8To14(config: config, dryRun: dryRun, forDisplay: forDisplay)
            switch config.task {
            case SharedReference.shared.synchronize:
                argumentsforsynchronize(dryRun: dryRun, forDisplay: forDisplay)
            case SharedReference.shared.snapshot:
                linkdestparameter(config: config, verify: false)
                argumentsforsynchronizesnapshot(dryRun: dryRun, forDisplay: forDisplay)
            case SharedReference.shared.syncremote:
                argumentsforsynchronizeremote(dryRun: dryRun, forDisplay: forDisplay)
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
