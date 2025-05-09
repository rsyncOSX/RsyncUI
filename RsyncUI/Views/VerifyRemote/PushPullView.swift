//
//  PushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct PushPullView: View {
    @State private var progress = true
    // Pull data from remote
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data to remote
    @State private var pushremotedatanumbers: RemoteDataNumbers?
    // Decide push or pull
    @State private var pushorpull = ObservablePushPull()
    // If aborted
    @State private var isaborted: Bool = false

    let config: SynchronizeConfiguration

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
                                                                                              removedelete: true)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: pullprocesstermination)
        process.executeProcess()
    }

    // For check remote, pull remote data
    func pushremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: true,
                                                                                           forDisplay: false,
                                                                                           removedelete: true)
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
        // Adjust both outputs
        pushorpull.adjustoutput()

        Task {
            pullremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpull)
            pushremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpush)
        }
    }

    func abort() {
        InterruptProcess()
    }
}
