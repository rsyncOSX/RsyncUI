//
//  PreandPostTasks.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/07/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct PreandPostTasks {
    // Pre and post tasks
    var executepretask: Bool = false
    var executeposttask: Bool = false

    init(config: Configuration?) {
        guard config != nil else { return }
        if let executepretask = config?.executepretask {
            if executepretask == 1, (config?.pretask?.count ?? 0) > 0 {
                self.executepretask = true
            }
            if let executeposttask = config?.executeposttask {
                if executeposttask == 1, (config?.posttask?.count ?? 0) > 0 {
                    self.executeposttask = true
                }
            }
        }
    }
}
