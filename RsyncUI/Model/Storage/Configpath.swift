//
//  Configpath.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/08/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct Configpath {
    var configpath: String?
    init() {
        if SharedReference.shared.usenewconfigpath == true {
            configpath = SharedReference.shared.newconfigpath
        } else {
            configpath = SharedReference.shared.configpath
        }
    }
}
