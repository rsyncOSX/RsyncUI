//
//  DeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/12/2024.
//

import Foundation
import OSLog
import RsyncUIDeepLinks

// URL code
@MainActor
struct DeeplinkURL {
    let deeplinks = RsyncUIDeepLinks()

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
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }

        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
        return nil
    }

    func validateProfile(_ profile: String?, _ validprofiles: [ProfilesnamesRecord]) -> Bool {
        if let profile {
            let profiles: [String] = validprofiles.map { record in
                record.profilename
            }

            do {
                try deeplinks.validateprofile(profile, profiles)
                return true
            } catch let e {
                let error = e
                SharedReference.shared.errorobject?.alert(error: error)
                return false
            }
        } else {
            // Default profile
            return true
        }
    }

    func validateNoAction(_ queryItem: URLQueryItem?) -> Bool {
        do {
            try deeplinks.validateNoOngoingURLAction(queryItem)
            return true
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
            return false
        }
    }

    func createURLestimateandsynchronize(valueprofile: String?) -> URL? {
        let host = Deeplinknavigation.loadprofileandestimate.rawValue
        var adjustedvalueprofile = valueprofile
        if valueprofile == nil {
            adjustedvalueprofile = "Default"
        }
        let queryitems: [URLQueryItem] = [URLQueryItem(name: "profile", value: adjustedvalueprofile)]
        if let url = deeplinks.createURL(host, queryitems) {
            return url
        } else {
            return nil
        }
    }
}
