//
//  WriteUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation
import OSLog

@MainActor
enum WriteUserConfigurationJSON {
    static func write(_ userconfiguration: UserConfiguration?) async {
        guard let userconfiguration else { return }

        let path = Homepath()
        guard let fullpathmacserial = path.fullpathmacserial else { return }

        let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
        let usercongigfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.userconfigjson)
        let snapshot = StoredUserConfiguration(
            rsyncversion3: userconfiguration.rsyncversion3,
            addsummarylogrecord: userconfiguration.addsummarylogrecord,
            localrsyncpath: userconfiguration.localrsyncpath,
            pathforrestore: userconfiguration.pathforrestore,
            marknumberofdayssince: userconfiguration.marknumberofdayssince,
            sshkeypathandidentityfile: userconfiguration.sshkeypathandidentityfile,
            sshport: userconfiguration.sshport,
            environment: userconfiguration.environment,
            environmentvalue: userconfiguration.environmentvalue,
            checkforerrorinrsyncoutput: userconfiguration.checkforerrorinrsyncoutput,
            confirmexecute: userconfiguration.confirmexecute,
            synchronizewithouttimedelay: userconfiguration.synchronizewithouttimedelay,
            sidebarishidden: userconfiguration.sidebarishidden,
            observemountedvolumes: userconfiguration.observemountedvolumes,
            alwaysshowestimateddetailsview: userconfiguration.alwaysshowestimateddetailsview,
            silencemissingstats: userconfiguration.silencemissingstats,
            validatearguments: userconfiguration.validatearguments
        )

        do {
            try await SharedJSONStorageWriter.shared.write(snapshot, to: usercongigfileURL)
            Logger.process.debugMessageOnly("WriteUserConfigurationJSON: Writing user configurations to permanent storage")
        } catch {
            Logger.process.errorMessageOnly("WriteUserConfigurationJSON: ERROR writing user configurations to permanent storage")
            path.propagateError(error: error)
        }
    }
}

private struct StoredUserConfiguration: Codable {
    var rsyncversion3: Int
    var addsummarylogrecord: Int
    var localrsyncpath: String?
    var pathforrestore: String?
    var marknumberofdayssince: String
    var sshkeypathandidentityfile: String?
    var sshport: Int?
    var environment: String?
    var environmentvalue: String?
    var checkforerrorinrsyncoutput: Int
    var confirmexecute: Int?
    var synchronizewithouttimedelay: Int
    var sidebarishidden: Int
    var observemountedvolumes: Int
    var alwaysshowestimateddetailsview: Int
    var silencemissingstats: Int
    var validatearguments: Int
}
