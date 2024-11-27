//
//  ObservableRemoteVSlocal.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/11/2024.
//

import Foundation
import Observation
import OSLog

enum RemoteVSlocal {
    case remotemoredata
    case localmoredata
    case evenamountadata
    case noevaluation
}

@Observable @MainActor
final class ObservableRemoteVSlocal {
    func decideremoteVSlocal(pullremotedatanumbers: RemoteDataNumbers?,
                             pushremotedatanumbers: RemoteDataNumbers?) -> RemoteVSlocal
    {
        if var pullremote = pullremotedatanumbers?.outputfromrsync,
           var pushremote = pushremotedatanumbers?.outputfromrsync
        {
            guard pullremote.count > 15, pushremote.count > 15 else { return .noevaluation }

            pullremote.removeLast(15)
            pushremote.removeLast(15)
            // Pull data <<--
            var setpullremote = Set(pullremote.compactMap { row in
                row.record.hasSuffix("/") == false ? row.record : nil
            })
            setpullremote.subtract(pushremote.compactMap { row in
                row.record.hasSuffix("/") == false ? row.record : nil
            })
            // Push data -->>
            var setpushremote = Set(pushremote.compactMap { row in
                row.record.hasSuffix("/") == false ? row.record : nil
            })
            setpushremote.subtract(pullremote.compactMap { row in
                row.record.hasSuffix("/") == false ? row.record : nil
            })

            if setpullremote.count > setpushremote.count {
                return .remotemoredata
            } else if setpullremote.count < setpushremote.count {
                return .localmoredata
            } else if setpullremote.count == setpushremote.count {
                return .evenamountadata
            }
        }
        return .noevaluation
    }

    deinit {
        Logger.process.info("ObservableRemoteVSlocal: deinit")
    }
}
