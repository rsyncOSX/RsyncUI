//
//  newVersion.swift
//  RsyncOSXver30
//
//  Created by Thomas Evensen on 02/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

protocol NewVersionDiscovered: AnyObject {
    func notifyNewVersion()
}

final class Checkfornewversion {
    private var runningVersion: String?
    private var urlPlist: String?
    private var urlNewVersion: String?

    weak var newversionDelegateMain: NewVersionDiscovered?
    weak var newversionDelegateAbout: NewVersionDiscovered?

    // If new version set URL for download link and notify caller
    private func urlnewVersion() {
        globalBackgroundQueue.async { () -> Void in
            if let url = URL(string: self.urlPlist ?? "") {
                do {
                    let contents = NSDictionary(contentsOf: url)
                    if let url = contents?.object(forKey: self.runningVersion ?? "") {
                        self.urlNewVersion = url as? String
                        // Setting reference to new version if any
                        SharedReference.shared.URLnewVersion = self.urlNewVersion
                    }
                }
            }
        }
    }

    // Return version of RsyncOSX
    func rsyncOSXversion() -> String? {
        return runningVersion
    }

    init() {
        runningVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let resource = Resources()
        urlPlist = resource.getResource(resource: .urlPlist)
        urlnewVersion()
    }
}
