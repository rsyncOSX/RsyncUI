//
//  PrepareParameters.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/09/2024.
//

import Foundation
import RsyncArguments

@MainActor
final class PrepareParameters {
    
    var parameters: Parameters?
    
    init(config: SynchronizeConfiguration) {
        parameters = Parameters(task: config.task,
                                parameter1: config.parameter1,
                                parameter2: config.parameter3,
                                parameter3: config.parameter3,
                                parameter4: config.parameter4,
                                parameter8: config.parameter8,
                                parameter9: config.parameter9,
                                parameter10: config.parameter10,
                                parameter11: config.parameter11,
                                parameter12: config.parameter12,
                                parameter13: config.parameter13,
                                parameter14: config.parameter14,
                                sshport: String(config.sshport ?? -1),
                                sshkeypathandidentityfile: config.sshkeypathandidentityfile,
                                sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
                                localCatalog: config.localCatalog,
                                offsiteCatalog: config.offsiteCatalog,
                                offsiteServer: config.offsiteServer,
                                offsiteUsername: config.offsiteUsername,
                                sharedpathforrestore: SharedReference.shared.pathforrestore ?? "",
                                snapshotnum: config.snapshotnum ?? -1,
                                rsyncdaemon: config.rsyncdaemon ?? -1,
                                rsyncversion3: SharedReference.shared.rsyncversion3)
    }
}

