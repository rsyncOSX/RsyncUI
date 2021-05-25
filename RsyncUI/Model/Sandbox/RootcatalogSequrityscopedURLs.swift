//
//  Sequrityscope.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 06/07/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

struct RootcatalogSequrityscopedURLs {
    @discardableResult
    init() {
        let rootcatalog = NamesandPaths(.configurations).userHomeDirectoryPath ?? ""
        AppendSequrityscopedURLs(path: rootcatalog)
    }
}
