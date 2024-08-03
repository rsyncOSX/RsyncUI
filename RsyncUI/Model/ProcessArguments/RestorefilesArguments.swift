//
//  RestorefilesArguments.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 27/06/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

enum Enumrestorefiles {
    case rsync
    case rsyncfilelistings
    case snapshotcatalogsonly
}

final class RestorefilesArguments {
    private var arguments: [String]?

    func getArguments() -> [String]? {
        arguments
    }

    init(task: Enumrestorefiles, config: SynchronizeConfiguration?,
         remoteFile: String?, localCatalog: String?, drynrun: Bool?,
         snapshot _: Bool)
    {
        if let config {
            arguments = [String]()
            let snapshot: Bool = (config.snapshotnum != nil) ? true : false
            switch task {
            case .rsync:
                let arguments = RsyncParametersSingleFilesArguments(config: config,
                                                                    remoteFile: remoteFile,
                                                                    localCatalog: localCatalog,
                                                                    drynrun: drynrun)
                self.arguments = arguments.getArguments()
            case .rsyncfilelistings:
                let arguments = GetRemoteFileListingsArguments(config: config,
                                                               recursive: true,
                                                               snapshot: snapshot)
                self.arguments = arguments.getArguments()
            case .snapshotcatalogsonly:
                let arguments = GetRemoteFileListingsArguments(config: config,
                                                               recursive: false,
                                                               snapshot: snapshot)
                self.arguments = arguments.getArguments()
            }
        }
    }
}
