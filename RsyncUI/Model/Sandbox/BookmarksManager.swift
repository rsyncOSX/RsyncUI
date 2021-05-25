//
//  BookmarksManager.swift
//  Sandbox
//
//  Created by Vincent Esche on 3/10/15.
//  Copyright (c) 2015 Vincent Esche. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

final class BookmarksManager {
    let userDefaults: UserDefaults
    static let defaultManager = BookmarksManager()
    static let userDefaultsBookmarksKey = "no.blogspot.RsyncUI"

    private var securityScopedBookmarksByFilePath: [String: NSData] {
        get {
            let bookmarksByFilePath = userDefaults.dictionary(forKey: BookmarksManager.userDefaultsBookmarksKey) as? [String: NSData]
            return bookmarksByFilePath ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: BookmarksManager.userDefaultsBookmarksKey)
        }
    }

    func clearSecurityScopedBookmarks() {
        securityScopedBookmarksByFilePath = [:]
    }

    func fileURLFromSecurityScopedBookmark(bookmark: NSData) -> URL? {
        let options: NSURL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
        var stale: ObjCBool = false
        if let fileURL = try? NSURL(resolvingBookmarkData: bookmark as Data, options: options,
                                    relativeTo: nil, bookmarkDataIsStale: &stale)
        {
            return fileURL as URL
        } else {
            return nil
        }
    }

    func loadSecurityScopedURLForFileAtURL(fileURL: URL) -> URL? {
        if let bookmark = loadSecurityScopedBookmarkForFileAtURL(fileURL: fileURL) {
            return fileURLFromSecurityScopedBookmark(bookmark: bookmark)
        }
        return nil
    }

    func loadSecurityScopedBookmarkForFileAtURL(fileURL: URL) -> NSData? {
        var resolvedFileURL: URL?
        resolvedFileURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()
        let bookmarksByFilePath = securityScopedBookmarksByFilePath
        var securityScopedBookmark = bookmarksByFilePath[resolvedFileURL!.path]
        while securityScopedBookmark == nil, resolvedFileURL!.pathComponents.count > 1 {
            resolvedFileURL = resolvedFileURL?.deletingLastPathComponent()
            securityScopedBookmark = bookmarksByFilePath[resolvedFileURL!.path]
        }
        return securityScopedBookmark
    }

    func securityScopedBookmarkForFileAtURL(fileURL: URL) -> NSData? {
        do {
            let bookmark = try fileURL.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope,
                                                    includingResourceValuesForKeys: nil, relativeTo: nil)
            return bookmark as NSData?
        } catch let e {
            let error = e as NSError
            propogateerror(error: error)
            return nil
        }
    }

    func saveSecurityScopedBookmarkForFileAtURL(securityScopedFileURL: URL) {
        if let bookmark = securityScopedBookmarkForFileAtURL(fileURL: securityScopedFileURL) {
            saveSecurityScopedBookmark(securityScopedBookmark: bookmark)
        }
    }

    func saveSecurityScopedBookmark(securityScopedBookmark: NSData) {
        if let fileURL = fileURLFromSecurityScopedBookmark(bookmark: securityScopedBookmark) {
            var savesecurityScopedBookmarks = securityScopedBookmarksByFilePath
            savesecurityScopedBookmarks[fileURL.path] = securityScopedBookmark
            securityScopedBookmarksByFilePath = savesecurityScopedBookmarks
        }
    }

    init() {
        userDefaults = UserDefaults.standard
    }
}

extension BookmarksManager: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
