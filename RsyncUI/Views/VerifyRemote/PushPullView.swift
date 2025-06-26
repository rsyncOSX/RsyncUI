//
//  PushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct PushPullView: View {
    
    @Binding var pushorpull: ObservableVerifyRemotePushPull
    
    @State private var progress = true
    // Pull data from remote, adjusted
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data to remote, adjusted
    @State private var pushremotedatanumbers: RemoteDataNumbers?
    // If aborted
    @State private var isaborted: Bool = false

    let config: SynchronizeConfiguration
    let isadjusted: Bool

    var body: some View {
        VStack {
            if progress {
                Spacer()

                ProgressView()
                    .toolbar(content: {
                        ToolbarItem {
                            Button {
                                isaborted = true
                                abort()
                            } label: {
                                Image(systemName: "stop.fill")
                            }
                            .help("Abort (⌘K)")
                        }
                    })

                Spacer()

            } else {
                if let pullremotedatanumbers, let pushremotedatanumbers {
                    HStack {
                        DetailsVerifyView(remotedatanumbers: pushremotedatanumbers,
                                          push: true)

                        DetailsVerifyView(remotedatanumbers: pullremotedatanumbers,
                                          push: false)
                    }
                }
            }
        }
        .onAppear {
            pullremote(config: config)
        }
    }

    // For check remote, pull remote data
    func pullremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                              forDisplay: false,
                                                                                              keepdelete: true)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: pullprocesstermination)
        process.executeProcess()
    }

    // For check remote, pull remote data
    func pushremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: true,
                                                                                           forDisplay: false,
                                                                                           keepdelete: true)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: pushprocesstermination)
        process.executeProcess()
    }

    func pullprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                      config: config)
        } else {
            pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                      config: config)
        }
        guard isaborted == false else {
            progress = false
            return
        }
        // Rsync output pull
        pushorpull.rsyncpull = stringoutputfromrsync
        pushorpull.rsyncpullmax = stringoutputfromrsync?.count ?? 0
        
        if isadjusted == false {
            Task {
                pullremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
            }
        }
        // Then do a synchronize task, adjusted for push vs pull
        pushremote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        guard isaborted == false else {
            progress = false
            return
        }
        progress = false
        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                      config: config)
        } else {
            pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                      config: config)
        }

        // Rsync output push
        pushorpull.rsyncpush = stringoutputfromrsync
        pushorpull.rsyncpushmax = stringoutputfromrsync?.count ?? 0
        
        if isadjusted {
            // Adjust both outputs
            pushorpull.adjustoutput()
            Task {
                pullremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpull)
                pushremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpush)
            }
        } else {
            Task {
                pushremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
            }
        }
    }

    func abort() {
        InterruptProcess()
    }
}
