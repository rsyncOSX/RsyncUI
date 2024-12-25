//
//  DeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/12/2024.
//

import Foundation
import OSLog

enum DeeplinknavigationError: LocalizedError {
    case invalidurl
    case invalidscheme
    case noaction

    var errorDescription: String? {
        switch self {
        case .invalidurl:
            "Invalid URL"
        case .invalidscheme:
            "Invalid URL scheme"
        case .noaction:
            "No action URL scheme"
        }
    }
}

enum Deeplinknavigation: String {
    case quicktask
    case loadprofile
    case loadandestimateprofile
}

struct DeeplinkQueryItem: Hashable {
    let host: Deeplinknavigation
    let queryItem: URLQueryItem?
}

struct DeeplinkURL: PropogateError {
    private func validateScheme(_ url: URL) throws -> URLComponents? {
        guard url.scheme == "rsyncuiapp" else { throw DeeplinknavigationError.invalidscheme }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            return components
        } else {
            throw DeeplinknavigationError.invalidurl
        }
    }

    private func thrownoaction() throws {
        throw DeeplinknavigationError.noaction
    }

    func handleURL(_ url: URL) -> DeeplinkQueryItem? {
        Logger.process.info("App was opened via URL: \(url)")

        var components: URLComponents?

        do {
            components = try validateScheme(url)
        } catch let e {
            Logger.process.info("Not a valid URL: \(url), invalid scheme")
            let error = e
            propogateerror(error: error)
        }

        if let components {
            if let queryItems = components.queryItems, queryItems.count == 1 {
                return withQueryItems(components)
            } else {
                return noQueryItems(components)
            }
        }
        do {
            try thrownoaction()
        } catch let e {
            let error = e
            propogateerror(error: error)
        }

        return nil
    }

    private func withQueryItems(_ components: URLComponents) -> DeeplinkQueryItem? {
        // First check if there are queryItems and only one queryItem
        // rsyncuiapp://loadandestimateprofile?profile=Pictures
        // rsyncuiapp://loadandestimateprofile?profile=default
        // rsyncuiapp://loadprofile?profile=Samsung

        if let queryItems = components.queryItems, queryItems.count == 1 {
            // Iterate through the query items and store them in the dictionary
            for queryItem in queryItems {
                if let value = queryItem.value {
                    let name = queryItem.name
                    Logger.process.info("Found query item: \(name) with value: \(value)")
                    // Found ... profile ...value: test
                }

                if let host = components.host {
                    switch host {
                    case Deeplinknavigation.loadprofile.rawValue:
                        Logger.process.info("Found host: \(host)")
                        let deepLinkQueryItem = DeeplinkQueryItem(host: .loadprofile, queryItem: queryItem)
                        return deepLinkQueryItem
                    case Deeplinknavigation.loadandestimateprofile.rawValue:
                        Logger.process.info("Found host: \(host)")
                        let deepLinkQueryItem = DeeplinkQueryItem(host: .loadandestimateprofile, queryItem: queryItem)
                        return deepLinkQueryItem
                    default:
                        Logger.process.info("No valid host, queryItems: nil")
                        return nil
                    }

                } else {
                    return nil
                }
            }
        }
        return nil
    }

    private func noQueryItems(_ components: URLComponents) -> DeeplinkQueryItem? {
        guard components.queryItems == nil else { return nil }
        // No queryItems found
        // rsyncuiapp://quicktask
        if let host = components.host {
            switch host {
            case Deeplinknavigation.quicktask.rawValue:
                Logger.process.info("Found host: \(host)")
                let deepLinkQueryItem = DeeplinkQueryItem(host: .quicktask, queryItem: nil)
                return deepLinkQueryItem
            default:
                Logger.process.info("No valid host, queryItem: nil")
                return nil
            }

        } else {
            return nil
        }
    }
}
