//
//  ProcessHandlers.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/11/2025.
//

import Foundation

@MainActor
struct ProcessHandlers {
    var processtermination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    var rsyncpath: () -> String?
    var checklineforerror: (String) throws -> Void
    var updateprocess: (Process?) -> Void
}

