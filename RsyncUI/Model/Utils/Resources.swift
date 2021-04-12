//
//  Resources.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/12/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length

import Foundation

// Enumtype type of resource
enum ResourceType {
    case changelog
    case documents
    case urlPLIST
    case urlJSON
}

struct Resources {
    // Resource strings
    private var changelog: String = "https://rsyncosx.netlify.app/post/changelog/"
    private var documents: String = "https://rsyncosx.netlify.app/post/rsyncosxdocs/"
    private var urlPLIST: String = "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/versionRsyncUI/versionRsyncUI.plist"
    private var urlJSON: String = "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/versionRsyncUI/versionrRsyncUI.json"
    // Get the resource.
    func getResource(resource: ResourceType) -> String {
        switch resource {
        case .changelog:
            return changelog
        case .documents:
            return documents
        case .urlPLIST:
            return urlPLIST
        case .urlJSON:
            return urlJSON
        }
    }
}
