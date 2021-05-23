//
//  Sequrityscope.swift
//  RsyncGUI
//
//  Created by Thomas Evensen on 06/07/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable  trailing_comma

import Foundation

struct RootcatalogSequrityscopedURLs {
    var dictionary: NSMutableDictionary?

    init() {
        let rootcatalog = NamesandPaths(.configurations).userHomeDirectoryPath ?? ""
        let append = AppendSequrityscopedURLs(path: rootcatalog)
        dictionary = [
            "rootcatalog": append.urlpath ?? "",
            "SecurityScoped": append.success,
        ]
    }
}
