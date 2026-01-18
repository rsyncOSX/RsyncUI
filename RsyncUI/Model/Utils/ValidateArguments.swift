//
//  ValidateArguments.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/12/2025.
//

import Foundation
import RsyncArguments

enum RemoteOrLocal {
    case remote
    case local
}

enum InvalidArguments: LocalizedError {
    case compress
    case archive
    case delete
    case nodelete
    case dryrun

    var errorDescription: String? {
        switch self {
        case .compress:
            "argument --compress is MISSING"
        case .archive:
            "argument --archive is MISSING"
        case .delete:
            "argument --delete is MISSING"
        case .nodelete:
            "argument --delete is INCLUDED"
        case .dryrun:
            "argument --dry-run is MISSING"
        }
    }
}

struct ValidateArguments {
    func validate(config: SynchronizeConfiguration, arguments: [String], isDryRun: Bool = false) throws {
        let remoteOrLocal: RemoteOrLocal = config.offsiteServer.isEmpty ? .local : .remote

        switch remoteOrLocal {
        case .remote:
            guard arguments.contains(DefaultRsyncParameters.compressionEnabled.rawValue) else {
                throw InvalidArguments.compress
            }

            guard arguments.contains(DefaultRsyncParameters.archiveMode.rawValue) else {
                throw InvalidArguments.archive
            }

        case .local:
            guard arguments.contains(DefaultRsyncParameters.compressionEnabled.rawValue) == false else {
                throw InvalidArguments.compress
            }

            guard arguments.contains(DefaultRsyncParameters.archiveMode.rawValue) else {
                throw InvalidArguments.archive
            }
        }

        if config.parameter4 == nil {
            guard arguments.contains(DefaultRsyncParameters.deleteExtraneous.rawValue) == false else {
                throw InvalidArguments.nodelete
            }
        } else {
            guard arguments.contains(DefaultRsyncParameters.deleteExtraneous.rawValue) else {
                throw InvalidArguments.delete
            }
        }

        if isDryRun {
            guard arguments.contains(DefaultRsyncParameters.dryRunMode.rawValue) else {
                throw InvalidArguments.dryrun
            }
        }

        // Validation passed
    }
}
