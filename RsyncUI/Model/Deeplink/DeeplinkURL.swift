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

enum Deeplinknavigation {
    case quicktask
    case noaction
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

    // rsyncuiapp://loadprofile?profile=test
    func handleURL(_ url: URL) -> Deeplinknavigation? {
        Logger.process.info("App was opened via URL: \(url)")

        var components: URLComponents?

        do {
            components = try validateScheme(url)
        } catch let e {
            let error = e
            propogateerror(error: error)
        }

        if let components {
            if let host = components.host {
                Logger.process.info("Found host: \(host)")
                // Found ... loadprofile
            }

            if let query = components.query {
                Logger.process.info("Found query: \(query)")
                // Found ... profile=test
            }

            if let queryItems = components.queryItems {
                // Iterate through the query items and store them in the dictionary
                for queryItem in queryItems {
                    if let value = queryItem.value {
                        let name = queryItem.name
                        Logger.process.info("Found query item: \(name) with value: \(value)")
                        // Found ... profile ...value: test
                    }
                }
            }

            // Must have a RETURN VALUE  here

            do {
                try thrownoaction()
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
        return nil
    }
}
