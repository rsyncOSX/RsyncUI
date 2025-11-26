//
//  URLExtensions.swift
//  RsyncUImenu
//
//  Created by Assistant on 11/24/2025.
//

import Foundation

public extension URL {
    static var userHomeDirectoryURLPath: URL? {
        FileManager.default.homeDirectoryForCurrentUser
    }
}
