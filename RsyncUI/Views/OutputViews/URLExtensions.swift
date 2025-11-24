//
//  URLExtensions.swift
//  RsyncUImenu
//
//  Created by Assistant on 11/24/2025.
//

import Foundation

public extension URL {
    /// Cross-platform helper returning a sensible writable directory for the current user.
    /// - On macOS this is the user's home directory.
    /// - On iOS/tvOS/watchOS this is the Documents directory within the app sandbox.
    static var userHomeDirectoryURLPath: URL? {
        return FileManager.default.homeDirectoryForCurrentUser
    }
}
