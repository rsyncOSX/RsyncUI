//
//  OutputRsyncCheckeRemoteView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

enum RemoteVSlocal {
    case remotemoredata
    case localmoredata
    case evenamountadata
    case noevaluation
}

struct OutputRsyncCheckeRemoteView: View {
    @State private var progress = true
    // Pull data fraom remote
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data from local to remote
    @State private var pushremotedatanumbers: RemoteDataNumbers?

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
                                                text: "PUSH local")
                        }
                    }
                }
            }
            if progress == false {
                switch decideremoteVSlocal {
                case .remotemoredata:
                    MessageView(mytext: "Seems to be more data in remote VS local.")
                case .localmoredata:
                    MessageView(mytext: "Seems to be more data in local VS remote.")
                case .evenamountadata:
                    MessageView(mytext: "Seems to even amount of data in local VS remote.")
                case .noevaluation:
                    MessageView(mytext: "Could not decide local VS remote.")
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
        pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
        // Then do a normal synchronize task
        pushremote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false
        pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
    }

    func abort() {
        _ = InterruptProcess()
    }
    
    var decideremoteVSlocal: RemoteVSlocal {
        if let pullremote = pullremotedatanumbers?.outputfromrsync,
           let pushremote = pushremotedatanumbers?.outputfromrsync {
            
            let countpullremote = pullremote.count - 15
            var i = 0
            let countpushremote = pushremote.count - 15
            var j = 0
            
            let trimmedpullremote = pullremote.compactMap {
                i += 1
                return i < countpullremote ? $0 : nil
            }
            let trimmedpushremote = pullremote.compactMap {
                j += 1
                return j < countpushremote ? $0 : nil
            }
            
            if trimmedpullremote.count > trimmedpushremote.count {
                return .remotemoredata
            } else if trimmedpullremote.count < trimmedpushremote.count {
                return .localmoredata
            } else if trimmedpullremote.count == trimmedpushremote.count {
                return .evenamountadata
            }
        }
        return .noevaluation
    }
}
