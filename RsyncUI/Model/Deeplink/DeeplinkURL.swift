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

    public func handleURL(_ url: URL) -> DeeplinkQueryItem? {
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
}
