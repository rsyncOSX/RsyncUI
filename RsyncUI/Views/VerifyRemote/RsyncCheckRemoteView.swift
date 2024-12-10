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
    @State private var pushVSremote = ObservableRemoteVSlocal()

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
                switch pushVSremote.decideremoteVSlocal(pullremotedatanumbers: pullremotedatanumbers,
                                                        pushremotedatanumbers: pushremotedatanumbers)
                {
                case .remotemoredata:
                    MessageView(mytext: "It seems that REMOTE is more updated than LOCAL. A PULL may be next.", size: .title3)
                case .localmoredata:
                    MessageView(mytext: "It seems that LOCAL is more updated than REMOTE. A SYNCHRONIZE may be next.", size: .title3)
                case .evenamountadata:
                    MessageView(mytext: "There’s an equal amount of data. Either do a SYNCHRONIZE or a PULL from remote.", size: .title3)
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

        pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
        Task {
            pullremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
        }
        // Then do a normal synchronize task
        pushremote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false
        pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
        Task {
            pushremotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
        }
    }

    func abort() {
        InterruptProcess()
    }
}
