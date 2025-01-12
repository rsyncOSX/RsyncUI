//
//  WidgetDeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/01/2025.
//

//
//  DeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/12/2024.
//

import Foundation
import RsyncUIDeepLinks

// URL code
@MainActor
struct WidgetDeeplinkURL {
    let deeplinks = RsyncUIDeepLinks()
    let validprofiles = WidgetHomepath().getfullpathmacserialcatalogsasstringnames()

    func handleURL(_ url: URL) -> DeeplinkQueryItem? {
        do {
            if let components = try deeplinks.validateScheme(url) {
                if let deepLinkQueryItem = deeplinks.handlevalidURL(components) {
                    if deepLinkQueryItem.host == .loadprofileandverify {
                        // guard SharedReference.shared.rsyncversion3 else { return nil }
                    }
                    return deepLinkQueryItem
                } else {
                    do {
                        try deeplinks.thrownoaction()
                    } catch {
                        return nil
                    }
                }
            }

        } catch {
            return nil
        }
        
        return nil
    }

    func validateprofile(_ profile: String) -> Bool {
        do {
            try deeplinks.validateprofile(profile, validprofiles)
            return true
        } catch {
            return false
        }
    }

    func validatenoaction(_ queryItem: URLQueryItem?) -> Bool {
        do {
            try deeplinks.validatenoongoingURLaction(queryItem)
            return true
        } catch {
            return false
        }
    }

    func createURLloadandverify(valueprofile: String, valueid: String) -> URL? {
        let host = Deeplinknavigation.loadprofileandverify.rawValue
        let adjustedvalueid = valueid.replacingOccurrences(of: " ", with: "_")
        var adjustedvalueprofile = valueprofile
        if valueprofile == "Default profile" {
            adjustedvalueprofile = "default"
        }
        let queryitems: [URLQueryItem] = [URLQueryItem(name: "profile", value: adjustedvalueprofile),
                                          URLQueryItem(name: "id", value: adjustedvalueid)]
        if let url = deeplinks.createURL(host, queryitems) {
            return url
        } else {
            return nil
        }
    }

    func createURLestimateandsynchronize(valueprofile: String) -> URL? {
        let host = Deeplinknavigation.loadprofileandestimate.rawValue
        var adjustedvalueprofile = valueprofile
        if valueprofile == "Default profile" {
            adjustedvalueprofile = "default"
        }
        let queryitems: [URLQueryItem] = [URLQueryItem(name: "profile", value: adjustedvalueprofile)]
        if let url = deeplinks.createURL(host, queryitems) {
            return url
        } else {
            return nil
        }
    }
}

