//
//  DeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/12/2024.
//

import Foundation
import OSLog
import RsyncUIDeepLinks

final class DeeplinkURL: PropogateError {
    let deeplinks = RsyncUIDeepLinks()
    let validprofiles = Homepath().getfullpathmacserialcatalogsasstringnames()

    func handleURL(_ url: URL) -> DeeplinkQueryItem? {
        do {
            if let components = try deeplinks.validateScheme(url) {
                if let deepLinkQueryItem = deeplinks.handlevalidURL(components) {
                    return deepLinkQueryItem
                } else {
                    do {
                        try deeplinks.thrownoaction()
                    } catch let e {
                        let error = e
                        propogateerror(error: error)
                    }
                }
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
        return nil
    }

    func validateprofile(_ profile: String) -> Bool {
        do {
            try deeplinks.validateprofile(profile, validprofiles)
            return true
        } catch let e {
            let error = e
            propogateerror(error: error)
            return false
        }
    }

    func validatenoaction(_ queryItem: URLQueryItem?) -> Bool {
        do {
            try deeplinks.validatenoongoingURLaction(queryItem)
            return true
        } catch let e {
            let error = e
            propogateerror(error: error)
            return false
        }
    }
}
