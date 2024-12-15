//
//  RsyncCheckRemoteView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct RsyncCheckRemoteView: View {
    @State private var progress = true
    // Pull data from remote
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data to remote
    @State private var pushremotedatanumbers: RemoteDataNumbers?
    // Temporary storage
    @State private var temporarystorage = TemporaryStoreOutput()

    let config: SynchronizeConfiguration

    var body: some View {
        VStack {
            HStack {
                if progress {
                    Spacer()

                    ProgressView()

                    Spacer()

                } else {
                    if let pullremotedatanumbers, let pushremotedatanumbers {
                        HStack {
                            DetailsPullPushView(remotedatanumbers: pullremotedatanumbers,
                                                text: "PULL remote")
                            DetailsPullPushView(remotedatanumbers: pushremotedatanumbers,
                                                text: "PUSH local (Synchronize)")
                        }
                    }
                }
            }
            if progress == false {
                switch temporarystorage.decideremoteVSlocal(pullremotedatanumbers: pullremotedatanumbers,
                                                        pushremotedatanumbers: pushremotedatanumbers)
                {
                case .remotemoredata:
                    MessageView(mytext: "It seems that REMOTE is more updated than LOCAL. A PULL may be next.", size: .title3)
                case .localmoredata:
                    MessageView(mytext: "It seems that LOCAL is more updated than REMOTE. A SYNCHRONIZE may be next.", size: .title3)
                case .evenamountadata:
                    MessageView(mytext: "There is an equal amount of data. You can either perform a SYNCHRONIZE operation or a PULL operation from the remote server.\nAlternatively, you can choose to do nothing.", size: .title3)
                case .noevaluation:
                    MessageView(mytext: "I couldn’t decide between LOCAL and REMOTE.", size: .title3)
                }
            }
        }
        .onAppear {
            pullremote(config: config)
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
    }

    // For check remote, pull remote data
    func pullremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                              forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: pullprocesstermination)
        process.executeProcess()
    }

    // For check remote, pull remote data
    func pushremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: true,
                                                                                           forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: pushprocesstermination)
        process.executeProcess()
    }

    func pullprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = Array(stringoutputfromrsync[stringoutputfromrsync.count - 20 ..< stringoutputfromrsync.count])
            pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                      config: config)
        } else {
            pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                      config: config)
        }
        // Rsync output pull
        temporarystorage.rsyncpull = stringoutputfromrsync
        // Then do a normal synchronize task
        pushremote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false
        pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
        // Rsync output push
        temporarystorage.rsyncpush = stringoutputfromrsync
        // Adjust both outputs
        temporarystorage.adjustoutput()
        
        Task {
            pullremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(temporarystorage.adjustedpull)
            
            pushremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(temporarystorage.adjustedpush)
        }
    }

    func abort() {
        InterruptProcess()
    }
}

import OSLog

enum RemoteVSlocal {
    case remotemoredata
    case localmoredata
    case evenamountadata
    case noevaluation
}

@Observable
final class TemporaryStoreOutput {
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
