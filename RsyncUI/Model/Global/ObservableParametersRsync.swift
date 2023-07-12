//
//  ObservableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import Foundation
import Observation

@Observable
final class ObservableParametersRsync {
    // Rsync parameters
    var parameter8: String = ""
    var parameter9: String = ""
    var parameter10: String = ""
    var parameter11: String = ""
    var parameter12: String = ""
    var parameter13: String = ""
    var parameter14: String = ""
    // Buttons
    var suffixlinux: Bool = false
    var suffixfreebsd: Bool = false
    var backup: Bool = false
    // Selected configuration
    var configuration: Configuration?

    func setvalues(_ config: Configuration?) {
        if let config = config {
            configuration = config
            parameter8 = configuration?.parameter8 ?? ""
            parameter9 = configuration?.parameter9 ?? ""
            parameter10 = configuration?.parameter10 ?? ""
            parameter11 = configuration?.parameter11 ?? ""
            parameter12 = configuration?.parameter12 ?? ""
            parameter13 = configuration?.parameter13 ?? ""
            parameter14 = configuration?.parameter14 ?? ""
        } else {
            reset()
        }
    }

    func setbackup() {
        if let config = configuration {
            let localcatalog = config.localCatalog
            let localcatalogparts = (localcatalog as AnyObject).components(separatedBy: "/")
            if parameter12.isEmpty == false {
                parameter12 = ""
            } else {
                parameter12 = RsyncArguments().backupstrings[0]
            }
            guard localcatalogparts.count > 2 else { return }
            if config.offsiteCatalog.contains("~") {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = RsyncArguments().backupstrings[1] + "_"
                        + localcatalogparts[localcatalogparts.count - 2]
                }
            } else {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = RsyncArguments().backupstrings[2] + "_"
                        + localcatalogparts[localcatalogparts.count - 2]
                }
            }
            configuration?.parameter12 = parameter12
            configuration?.parameter13 = parameter13
        }
    }

    func setsuffixlinux() {
        guard configuration != nil else { return }
        if parameter14.isEmpty == false {
            if parameter14 == RsyncArguments().suffixstringfreebsd {
                parameter14 = RsyncArguments().suffixstringlinux
            } else {
                parameter14 = ""
            }
        } else {
            parameter14 = RsyncArguments().suffixstringlinux
        }
        configuration?.parameter14 = parameter14
    }

    func setsuffixfreebsd() {
        guard configuration != nil else { return }
        if parameter14.isEmpty == false {
            if parameter14 == RsyncArguments().suffixstringlinux {
                parameter14 = RsyncArguments().suffixstringfreebsd
            } else {
                parameter14 = ""
            }
        } else {
            parameter14 = RsyncArguments().suffixstringfreebsd
        }
        configuration?.parameter14 = parameter14
    }

    // Return the updated configuration
    func updatersyncparameters() -> Configuration? {
        if var configuration = configuration {
            if parameter8.isEmpty { configuration.parameter8 = nil } else { configuration.parameter8 = parameter8 }
            if parameter9.isEmpty { configuration.parameter9 = nil } else { configuration.parameter9 = parameter9 }
            if parameter10.isEmpty { configuration.parameter10 = nil } else { configuration.parameter10 = parameter10 }
            if parameter11.isEmpty { configuration.parameter11 = nil } else { configuration.parameter11 = parameter11 }
            if parameter12.isEmpty { configuration.parameter12 = nil } else { configuration.parameter12 = parameter12 }
            if parameter13.isEmpty { configuration.parameter13 = nil } else { configuration.parameter13 = parameter13 }
            if parameter14.isEmpty { configuration.parameter14 = nil } else { configuration.parameter14 = parameter14 }
            return configuration
        }
        return nil
    }

    func reset() {
        configuration = nil
        parameter8 = ""
        parameter9 = ""
        parameter10 = ""
        parameter11 = ""
        parameter12 = ""
        parameter13 = ""
        parameter14 = ""
    }
}

enum ParameterError: LocalizedError {
    case notvalid

    var errorDescription: String? {
        switch self {
        case .notvalid:
            return "Not a valid "
        }
    }
}
