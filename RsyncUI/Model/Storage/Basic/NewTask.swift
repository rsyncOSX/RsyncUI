//
//  NewTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 30/12/2025.
//

import Foundation

struct NewTask {
    var newtask: String
    var newlocalCatalog: String
    var newoffsiteCatalog: String
    var newtrailingslashoptions: TrailingSlash
    // Can be nil
    var newoffsiteUsername: String?
    var newoffsiteServer: String?
    var newbackupID: String?
    // Use hiddenID for update
    var hiddenID: Int?
    // For snapshottask, snapshotnum might be reset
    var snapshotnum: Int?

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingslashoptions: TrailingSlash,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?) {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newtrailingslashoptions = trailingslashoptions
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
    }

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingslashoptions: TrailingSlash,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?,
         _ updatedhiddenID: Int,
         _ updatesnapshotnum: Int?) {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newtrailingslashoptions = trailingslashoptions
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
        hiddenID = updatedhiddenID
        snapshotnum = updatesnapshotnum
    }
}
