//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct UserConfiguration: Codable {
    var rsyncversion3: Int = -1
    // Detailed logging
    var detailedlogging: Int = 1
    // Logging to logfile
    var minimumlogging: Int = -1
    var fulllogging: Int = -1
    var nologging: Int = 1

    private func setuserconfigdata() {
        if rsyncversion3 == 1 {
            SharedReference.shared.rsyncversion3 = true
        } else {
            SharedReference.shared.rsyncversion3 = false
        }
        if detailedlogging == 1 {
            SharedReference.shared.detailedlogging = true
        } else {
            SharedReference.shared.detailedlogging = false
        }
        if minimumlogging == 1 {
            SharedReference.shared.minimumlogging = true
        } else {
            SharedReference.shared.minimumlogging = false
        }
        if fulllogging == 1 {
            SharedReference.shared.fulllogging = true
        } else {
            SharedReference.shared.fulllogging = false
        }
        if nologging == 1 {
            SharedReference.shared.nologging = true
        } else {
            SharedReference.shared.nologging = false
        }
    }

    // Used when reading JSON data from store
    @discardableResult
    init(_ data: DecodeUserConfiguration) {
        rsyncversion3 = data.rsyncversion3 ?? -1
        detailedlogging = data.detailedlogging ?? 1
        minimumlogging = data.minimumlogging ?? -1
        fulllogging = data.fulllogging ?? -1
        nologging = data.nologging ?? 1
        // Set user configdata read from permanent store
        setuserconfigdata()
    }

    // Default values user configuration
    @discardableResult
    init(_ save: Bool) {
        if save {
            if SharedReference.shared.rsyncversion3 {
                rsyncversion3 = 1
            } else {
                rsyncversion3 = -1
            }
            if SharedReference.shared.detailedlogging {
                detailedlogging = 1
            } else {
                detailedlogging = -1
            }
            if SharedReference.shared.minimumlogging {
                minimumlogging = 1
            } else {
                minimumlogging = -1
            }
            if SharedReference.shared.fulllogging {
                fulllogging = 1
            } else {
                fulllogging = -1
            }
            if SharedReference.shared.nologging {
                nologging = 1
            } else {
                nologging = -1
            }
        }
    }
}
