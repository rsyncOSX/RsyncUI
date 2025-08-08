//
//  PushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct PushPullView: View {
    @Binding var pushorpull: ObservableVerifyRemotePushPull
    @Binding var verifypath: [Verify]
    @Binding var pushpullcommand: PushPullCommand

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

                Spacer()

            } else {
                if let pullremotedatanumbers, let pushremotedatanumbers {
                    HStack {
                        VStack {
                            Button {
                                pushpullcommand = .push_local
                                verifypath.removeAll()
                                verifypath.append(Verify(task: .executenpushpullview))
                            } label: {
                                Image(systemName: "arrowshape.right.fill")
                                    .font(.title2)
                                    .imageScale(.large)
                            }
                            .help("Push local")
                            .padding(10)

                            DetailsVerifyView(remotedatanumbers: pushremotedatanumbers)
                                .padding(10)
                        }

                        VStack {
                            Button {
                                pushpullcommand = .pull_remote
                                verifypath.removeAll()
                                verifypath.append(Verify(task: .executenpushpullview))
                            } label: {
                                Image(systemName: "arrowshape.left.fill")
                                    .font(.title2)
                                    .imageScale(.large)
                            }
                            .help("Pull remote")
                            .padding(10)

                            DetailsVerifyView(remotedatanumbers: pullremotedatanumbers)
                                .padding(10)
                        }
                    }
                }
            }
        }
        .onAppear {
            pullremote(config: config)
        }
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
                pullremotedatanumbers?.outputfromrsync = await ActorCreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
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
                pullremotedatanumbers?.outputfromrsync = await ActorCreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpull)
                pushremotedatanumbers?.outputfromrsync = await ActorCreateOutputforviewOutputRsync().createoutputforviewoutputrsync(pushorpull.adjustedpush)
            }
        } else {
            Task {
                pushremotedatanumbers?.outputfromrsync = await ActorCreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
            }
        }
    }

    func abort() {
        InterruptProcess()
    }
}
