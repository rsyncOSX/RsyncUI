//
//  PushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import OSLog
import RsyncProcess
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

                HStack {
                    Text("Estimating \(config.backupID), please wait ...")
                        .font(.title2)

                    ProgressView()
                }

                Spacer()

            } else {
                if let pullremotedatanumbers, let pushremotedatanumbers {
                    VStack {
                        Text(" \(config.backupID)")
                            .font(.title2)

                        HStack {
                            VStack {
                                ConditionalGlassButton(
                                    systemImage: "arrowshape.right.fill",
                                    helpText: "Push local"
                                ) {
                                    pushpullcommand = .push_local
                                    verifypath.removeAll()
                                    verifypath.append(Verify(task: .executenpushpullview(configID: config.id)))
                                }
                                .padding(10)

                                DetailsVerifyView(remotedatanumbers: pushremotedatanumbers)
                                    .padding(10)
                            }

                            VStack {
                                ConditionalGlassButton(
                                    systemImage: "arrowshape.left.fill",
                                    helpText: "Pull remote"
                                ) {
                                    pushpullcommand = .pull_remote
                                    verifypath.removeAll()
                                    verifypath.append(Verify(task: .executenpushpullview(configID: config.id)))
                                }
                                .padding(10)

                                DetailsVerifyView(remotedatanumbers: pullremotedatanumbers)
                                    .padding(10)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            pullremote(config: config)
        }
        .toolbar(content: {
            if progress {
                ToolbarItem {
                    ConditionalGlassButton(
                        systemImage: "stop.fill",
                        helpText: "Abort"
                    ) {
                        isaborted = true
                        abort()
                    }
                }
            }
        })
    }

    // For check remote, pull remote data
    func pullremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                              forDisplay: false,
                                                                                              keepdelete: true)

        let handlers = CreateHandlers().createhandlers(
            filehandler: { _ in },
            processtermination: pullprocesstermination
        )

        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }

        let process = RsyncProcess(arguments: arguments,
                                   hiddenID: config.hiddenID,
                                   handlers: handlers,
                                   usefilehandler: false)
        do {
            try process.executeProcess()
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    // For check remote, pull remote data
    func pushremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremotewithparameters(dryRun: true,
                                                                                                         forDisplay: false,
                                                                                                         keepdelete: true)
        let handlers = CreateHandlers().createhandlers(
            filehandler: { _ in },
            processtermination: pushprocesstermination
        )

        let process = RsyncProcess(arguments: arguments,
                                   hiddenID: config.hiddenID,
                                   handlers: handlers,
                                   usefilehandler: false)
        do {
            try process.executeProcess()
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
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
        pushorpull.rsyncpullmax = (stringoutputfromrsync?.count ?? 0) - 16
        if pushorpull.rsyncpullmax < 0 {
            pushorpull.rsyncpullmax = 0
        }

        if isadjusted == false {
            Task {
                pullremotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)
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
        pushorpull.rsyncpushmax = (stringoutputfromrsync?.count ?? 0) - 16
        if pushorpull.rsyncpushmax < 0 {
            pushorpull.rsyncpushmax = 0
        }

        if isadjusted {
            // Adjust both outputs
            pushorpull.adjustoutput()
            Task {
                pullremotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createaoutputforview(pushorpull.adjustedpull)
                pushremotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createaoutputforview(pushorpull.adjustedpush)
            }
        } else {
            Task {
                pushremotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)
            }
        }
    }

    func abort() {
        InterruptProcess()
    }
}
