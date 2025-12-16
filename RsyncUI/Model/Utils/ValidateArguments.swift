//
//  ValidateArguments.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/12/2025.
//

import Foundation

enum RemoteOrLocal {
    case remote
    case local
}

enum InvalidArguments: LocalizedError {
    case compress
    case archive
    case delete
    case nodelete

    var errorDescription: String? {
        switch self {
        case .compress:
            return "argument --compress is MISSING"
        case .archive:
            return "argument --archive is MISSING"
        case .delete:
            return "argument --delete is MISSING"
        case .nodelete:
            return "argument --delete is INCLUDED"
        }
    }
}

struct ValidateArguments {

    func validate(config: SynchronizeConfiguration, arguments: [String]) throws {

        let remoteOrLocal: RemoteOrLocal = config.offsiteServer.isEmpty ? .local : .remote

        switch remoteOrLocal {
        case .remote:
            guard arguments.contains("--compress") else {
                throw InvalidArguments.compress
            }

            guard arguments.contains("--archive") else {
                throw InvalidArguments.archive
            }

        case .local:
            guard arguments.contains("--compress") == false else {
                throw InvalidArguments.compress
            }

            guard arguments.contains("--archive") else {
                throw InvalidArguments.archive
            }
        }

        if config.parameter4 == nil {
            guard arguments.contains("--delete") == false else {
                throw InvalidArguments.nodelete
            }
        } else {
            guard arguments.contains("--delete") else {
                throw InvalidArguments.delete
            }
        }

        // Validation passed
    }
}
