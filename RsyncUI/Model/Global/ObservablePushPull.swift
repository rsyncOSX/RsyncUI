//
//  ObservablePushPull.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/12/2024.
//

import OSLog

enum RemoteVSlocal {
    case remotemoredata
    case localmoredata
    case evenamountadata
    case noevaluation
}

@Observable
final class ObservablePushPull {
    @ObservationIgnored var adjustedpull: Set<String>?
    @ObservationIgnored var adjustedpush: Set<String>?
    
    @ObservationIgnored var rsyncpull: [String]?
    @ObservationIgnored var rsyncpush: [String]?
    
    
    func adjustoutput() {
        if var pullremote = rsyncpull,
           var pushremote = rsyncpush
        {
            guard pullremote.count > 17, pushremote.count > 17 else { return }
            
            pullremote.removeFirst()
            pushremote.removeFirst()
            
            pullremote.removeLast(17)
            pushremote.removeLast(17)
            
            // Pull data <<--
            var setpullremote = Set(pullremote.compactMap { row in
                row.hasSuffix("/") == false ? row : nil
            })
            setpullremote.subtract(pushremote.compactMap { row in
                row.hasSuffix("/") == false ? row : nil
            })
            
            adjustedpull = setpullremote
            
            // Push data -->>
            var setpushremote = Set(pushremote.compactMap { row in
                row.hasSuffix("/") == false ? row : nil
            })
            setpushremote.subtract(pullremote.compactMap { row in
                row.hasSuffix("/") == false ? row : nil
            })
            
            adjustedpush = setpushremote
        }
    }
    
    func decideremoteVSlocal(pullremotedatanumbers: RemoteDataNumbers?,
                             pushremotedatanumbers: RemoteDataNumbers?) -> RemoteVSlocal
    {
        if let pullremote = pullremotedatanumbers?.outputfromrsync,
           let pushremote = pushremotedatanumbers?.outputfromrsync
        {
            
            if pullremote.count > pushremote.count {
                return .remotemoredata
            } else if pullremote.count < pushremote.count {
                return .localmoredata
            } else if pullremote.count == pushremote.count {
                return .evenamountadata
            }
        }
        return .noevaluation
    }

    deinit {
        Logger.process.info("TemporaryStoreOutput: deinit")
    }
}
