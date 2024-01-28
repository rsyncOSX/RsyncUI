//
//  MyEnvironment.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 02/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

struct MyEnvironment {
    var environment: [String: String]?

    init?() {
        if let environment = SharedReference.shared.environment {
            if let environmentvalue = SharedReference.shared.environmentvalue {
                self.environment = [environment: environmentvalue]
            }
        }
    }
}
