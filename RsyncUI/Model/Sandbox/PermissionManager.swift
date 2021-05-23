//
//  PermissionManager.swift
//  Sandbox
//
//  Created by Vincent Esche on 3/10/15.
//  Copyright (c) 2015 Vincent Esche. All rights reserved.
//
// swiftlint: disable line_length

import Cocoa

final class OpenPanelDelegate: NSObject, OpenPanelDelegateType {
    var fileURL: NSURL!
}

protocol OpenPanelDelegateType: NSOpenSavePanelDelegate {
    var fileURL: NSURL! { get set }
}

public class PermissionManager {
    let bookmarksManager: BookmarksManager
    lazy var openPanelDelegate: OpenPanelDelegateType = OpenPanelDelegate()
    lazy var openPanel: NSOpenPanel = OpenPanelBuilder().openPanel()
    static let defaultManager = PermissionManager()

    func needsPermissionForFileAtURL(fileURL: URL) -> Bool {
        let reachable = try? fileURL.checkResourceIsReachable()
        let readable = FileManager.default.isReadableFile(atPath: fileURL.absoluteString)
        return reachable ?? false && !readable
    }

    func askUserForSecurityScopeForFileAtURL(fileURL: URL) -> URL? {
        if !needsPermissionForFileAtURL(fileURL: fileURL) { return fileURL }
        let openPanel = self.openPanel
        if openPanel.directoryURL == nil {
            openPanel.directoryURL = fileURL.deletingLastPathComponent()
        }
        let openPanelDelegate = self.openPanelDelegate
        openPanelDelegate.fileURL = fileURL as NSURL
        openPanel.delegate = openPanelDelegate
        var securityScopedURL: URL?
        let closure: () -> Void = {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if openPanel.runModal().rawValue == NSApplication.ModalResponse.OK.rawValue {
                securityScopedURL = openPanel.url as URL?
            }
            openPanel.delegate = nil
        }
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.sync(execute: closure)
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
