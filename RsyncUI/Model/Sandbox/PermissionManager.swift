//
//  PermissionManager.swift
//  Sandbox
//
//  Created by Vincent Esche on 3/10/15.
//  Copyright (c) 2015 Vincent Esche. All rights reserved.
//
// swiftlint: disable line_length

import Cocoa
import SwiftUI

public class PermissionManager {
    let bookmarksManager: BookmarksManager
    static let defaultManager = PermissionManager()

    var userHomeDirectoryPath: URL? {
        let pw = getpwuid(getuid())
        if let homeptr = pw?.pointee.pw_dir {
            let homePath = FileManager.default.string(withFileSystemRepresentation: homeptr, length: Int(strlen(homeptr)))
            return URL(string: homePath) ?? URL(string: "")
        }
        return URL(string: "")
    }

    func needsPermissionForFileAtURL(fileURL: URL) -> Bool {
        let reachable = try? fileURL.checkResourceIsReachable()
        let readable = FileManager.default.isReadableFile(atPath: fileURL.absoluteString)
        return reachable ?? false && !readable
    }

    func askUserForSecurityScopeForFileAtURL(fileURL: URL) -> URL? {
        if needsPermissionForFileAtURL(fileURL: fileURL) == false { return fileURL }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.isExtensionHidden = false
        panel.showsHiddenFiles = false
        panel.title = "self.title"
        panel.message = "self.message"
        panel.prompt = "self.prompt"
        panel.directoryURL = userHomeDirectoryPath
        if panel.directoryURL == nil {
            panel.directoryURL = fileURL.deletingLastPathComponent()
        }
        var securityScopedURL: URL?
        if panel.runModal().rawValue == NSApplication.ModalResponse.OK.rawValue {
            securityScopedURL = panel.url as URL?
        }
        if let pathforcatalog = securityScopedURL {
            bookmarksManager.saveSecurityScopedBookmarkForFileAtURL(securityScopedFileURL: pathforcatalog)
        }
        return securityScopedURL
    }

    func accessSecurityScopedFileAtURL(fileURL: URL) -> Bool {
        let accessible = fileURL.startAccessingSecurityScopedResource()
        if accessible {
            return true
        } else {
            return false
        }
    }

    func accessAndIfNeededAskUserForSecurityScopeForFileAtURL(fileURL: URL) -> Bool {
        if needsPermissionForFileAtURL(fileURL: fileURL) == false { return true }
        let bookmarkedURL = bookmarksManager.loadSecurityScopedURLForFileAtURL(fileURL: fileURL)
        let securityScopedURL = bookmarkedURL ?? askUserForSecurityScopeForFileAtURL(fileURL: fileURL)
        if securityScopedURL != nil {
            return accessSecurityScopedFileAtURL(fileURL: securityScopedURL!)
        }
        return false
    }

    init(bookmarksManager: BookmarksManager = BookmarksManager()) {
        self.bookmarksManager = bookmarksManager
    }
}

struct Test: View {
    @State var filename = "Filename"
    @State var showFileChooser = false

    var body: some View {
        HStack {
            Text(filename)
            Button("select File") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK {
                    self.filename = panel.url?.lastPathComponent ?? "<none>"
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
