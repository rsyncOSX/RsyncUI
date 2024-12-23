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
}

struct DeeplinkURL {
    func handleURL(_ url: URL) -> Deeplinknavigation {
        Logger.process.info("App was opened via URL: \(url)")
        guard url.scheme == "rsyncuiapp" else { return .invalidscheme }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            Logger.process.warning("Invalid URL")
            return .invalidurl
        }

        print(components)
        return .quicktask
    }
}
