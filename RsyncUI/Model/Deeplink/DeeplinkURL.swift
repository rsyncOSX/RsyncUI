//
//  DeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/12/2024.
//

import Foundation
import OSLog

enum Deeplinknavigation {
    case quicktask
    case invalidurl
    case invalidscheme
    case noaction
}

struct DeeplinkURL {
    private func validateScheme(_ scheme: String) -> Bool {
        guard scheme == "rsyncuiapp" else { return false }
        return true
    }
    
    // rsyncuiapp://loadprofile?profile=test
    func handleURL(_ url: URL) -> Deeplinknavigation {
        
        Logger.process.info("App was opened via URL: \(url)")
        
        guard (url.scheme != nil) else { return .invalidurl }
        
        if let scheme = url.scheme {
            guard validateScheme(scheme) else { return .invalidscheme }
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                Logger.process.warning("Invalid URL")
                return .invalidurl
            }

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
                queryItems.forEach ({
                    if let value = $0.value {
                       let name = $0.name
                        Logger.process.info("Found query item: \(name) with value: \(value)")
                        // Found ... profile ...value: test
                    }
                })
            }
            
            return .noaction
            
            // return .quicktask
        }
        return .invalidurl
    }
}
