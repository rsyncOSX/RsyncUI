//
//  scpNSTaskArguments.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 27/06/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length

import Foundation

enum Enumrestorefiles {
    case rsync
    case rsyncfilelistings
    case snapshotcatalogsonly
}

final class RestorefilesArguments {
    private var arguments: [String]?

    func getArguments() -> [String]? {
        return arguments
    }

    init(task: Enumrestorefiles, config: Configuration?, remoteFile: String?, localCatalog: String?, drynrun: Bool?) {
        if let config = config {
            arguments = [String]()
            switch task {
            case .rsync:
                let arguments = RsyncParametersSingleFilesArguments(config: config, remoteFile: remoteFile, localCatalog: localCatalog, drynrun: drynrun)
                self.arguments = arguments.getArguments()
            case .rsyncfilelistings:
                let arguments = GetRemoteFileListingsArguments(config: config, recursive: true)
                self.arguments = arguments.getArguments()
            case .snapshotcatalogsonly:
                let arguments = GetRemoteFileListingsArguments(config: config, recursive: false)
                self.arguments = arguments.getArguments()
            }
        }
    }
}
