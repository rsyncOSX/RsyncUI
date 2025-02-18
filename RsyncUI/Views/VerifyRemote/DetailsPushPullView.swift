//
//  DetailsPushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

enum SwiftPushPullView: String, CaseIterable, Identifiable, CustomStringConvertible {
    case pull
    case push
    case both

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

struct DetailsPushPullView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var verifynavigation: [VerifyTasks]
    // URL code
    @Binding var queryitem: URLQueryItem?

    @State private var progress = true
    // Pull data from remote
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data to remote
    @State private var pushremotedatanumbers: RemoteDataNumbers?
    // Decide push or pull
    @State private var pushorpull = ObservablePushPull()
    // Switch view
    @State private var switchview: SwiftPushPullView = .both
    // Is presented
    @State private var ispresented: Bool = false

    let config: SynchronizeConfiguration

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    if progress {
                        Spacer()

                        ProgressView()

                        Spacer()

                    } else {
                        if let pullremotedatanumbers, let pushremotedatanumbers {
                            if switchview == .both {
                                HStack {
                                    DetailsPullPushView(remotedatanumbers: pushremotedatanumbers,
                                                        text: "PUSH local (Synchronize)")

                                    DetailsPullPushView(remotedatanumbers: pullremotedatanumbers,
                                                        text: "PULL remote")
                                }
                            } else if switchview == .push {
                                DetailsPullPushView(remotedatanumbers: pushremotedatanumbers,
                                                    text: "PUSH local (Synchronize)")
                            } else {
                                DetailsPullPushView(remotedatanumbers: pullremotedatanumbers,
                                                    text: "PULL remote")
                            }
                        }
                    }
                }

                if progress == false {
                    switch pushorpull.decideremoteVSlocal(pullremotedatanumbers: pullremotedatanumbers,
                                                          pushremotedatanumbers: pushremotedatanumbers)
                    {
                    case .remotemoredata:
                        MessageView(mytext: NSLocalizedString("It seems that REMOTE is more updated than LOCAL. A PULL may be next.", comment: ""), size: .title3)
                    case .localmoredata:
                        MessageView(mytext: NSLocalizedString("It seems that LOCAL is more updated than REMOTE. A SYNCHRONIZE may be next.", comment: ""), size: .title3)
                    case .evenamountadata:
                        MessageView(mytext: NSLocalizedString("There is an equal amount of data. You can either perform a SYNCHRONIZE or a PULL operation.\n Alternatively, you can choose to do nothing.", comment: ""), size: .title3)
                    case .noevaluation:
                        MessageView(mytext: NSLocalizedString("I couldn’t decide between LOCAL and REMOTE.", comment: ""), size: .title3)
                    }
                }
            }
            .onAppear {
                pullremote(config: config)
            }
            .toolbar(content: {
                if progress == false {
                    ToolbarItem {
                        pickerselectview
                    }

                    ToolbarItem {
                        Button {
                            // verifynavigation.removeAll()
                            // verifynavigation.append(VerifyTasks(task: .executepushpull))
                            ispresented = true
                        } label: {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .help("Pull or push")
                    }
                }

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
        .navigationTitle("Verify remote")
        .navigationDestination(isPresented: $ispresented) {
            ExecutePushPullView(verifynavigation: $verifynavigation,
                                config: config, profile: rsyncUIdata.profile)
        }
    }

    var pickerselectview: some View {
        Picker("", selection: $switchview) {
            ForEach(SwiftPushPullView.allCases) { Text($0.description)
                .tag($0)
            }
        }
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
        pushorpull.rsyncpull = stringoutputfromrsync
        // Then do a synchronize task, adjusted for push vs pull
        pushremote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushprocesstermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false
        pushremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
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
