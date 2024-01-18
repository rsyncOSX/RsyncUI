//
//  DefaultFilesJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/01/2024.
//

import Foundation
import OSLog

class DefaultFilesJSON: NamesandPaths {
    private func validatepath(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path, isDirectory: nil)
    }

    private func createdefaultfilesJSON(_ profile: String?) {
        if let atpath = fullpathmacserial {
            var oldfilelogrecords = ""
            var newfilelogrecords = ""
            var oldfileexists = true
            var newfileexists = false
            do {
                if profile != nil {
                    oldfilelogrecords = atpath + "/" + (profile ?? "") + "/" + SharedReference.shared.fileschedulesjson
                    newfilelogrecords = atpath + "/" + (profile ?? "") + "/" + SharedReference.shared.filenamelogrecordsjson
                } else {
                    oldfilelogrecords = atpath + "/" + SharedReference.shared.fileschedulesjson
                    newfilelogrecords = atpath + "/" + SharedReference.shared.filenamelogrecordsjson
                }
                oldfileexists = validatepath(oldfilelogrecords)
                newfileexists = validatepath(newfilelogrecords)
                if oldfileexists == true, newfileexists == false {
                    SharedReference.shared.defaultlogfileexist = false
                    SharedReference.shared.copydataoldlogfiletonewlogfile = true
                } else if oldfileexists == false, newfileexists == false {
                    SharedReference.shared.defaultlogfileexist = false
                    SharedReference.shared.copydataoldlogfiletonewlogfile = false
                }
            }
        }
    }

    init(_ profile: String?) {
        super.init(.configurations)
        // Reset defaults
        SharedReference.shared.defaultlogfileexist = true
        SharedReference.shared.copydataoldlogfiletonewlogfile = false
        // Check and set flags
        createdefaultfilesJSON(profile)
    }
}
