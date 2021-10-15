//
//  ArgumentsLocalcatalogInfo.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsLocalcatalogInfo: ComputeRsyncParameters {
    var config: Configuration?

    func argumentslocalcataloginfo(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config = config {
            localCatalog = config.localCatalog
            setParameters1To6(config: config, dryRun: dryRun, forDisplay: forDisplay, verify: false)
            setParameters8To14(config: config, dryRun: dryRun, forDisplay: forDisplay)
            switch config.task {
            case SharedReference.shared.synchronize:
                argumentsforsynchronize(dryRun: dryRun, forDisplay: forDisplay)
            case SharedReference.shared.snapshot:
                argumentsforsynchronizesnapshot(dryRun: dryRun, forDisplay: forDisplay)
            case SharedReference.shared.syncremote:
                return []
            default:
                break
            }
            return arguments
        }
        return nil
    }

    init(config: Configuration?) {
        super.init()
        self.config = config
    }
}
