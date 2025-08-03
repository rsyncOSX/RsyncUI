//
//  ExecutePushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2024.
//

import SwiftUI

struct ExecutePushPullView: View {
    @Binding var pushorpull: ObservableVerifyRemotePushPull

    @State private var showprogressview = false
    @State private var remotedatanumbers: RemoteDataNumbers?
    @Binding var pushpullcommand: PushPullCommand

    @State private var dryrun: Bool = true
    @State private var keepdelete: Bool = true

    @State private var progress: Double = 0

    let config: SynchronizeConfiguration

    var body: some View {
        HStack {
            if let remotedatanumbers {
                DetailsView(remotedatanumbers: remotedatanumbers)
            } else {
                if showprogressview == false {
                    VStack {
                        HStack {
                            VStack(alignment: .trailing) {
                                Toggle("--dry-run", isOn: $dryrun)
                                    .toggleStyle(.switch)
                                    .onTapGesture {
                                        withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                            dryrun.toggle()
                                        }
                                    }

                                Toggle("--delete", isOn: $keepdelete)
                                    .toggleStyle(.switch)
                                    .onTapGesture {
                                        withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                            keepdelete.toggle()
                                        }
                                    }
                                    .help("Remove the delete parameter, default is true?")
                            }

                            if pushpullcommand == .push_local {
                                Button("Push") {
                                    showprogressview = true
                                    push(config: config)
                                }
                                .padding()
                                .buttonStyle(ColorfulButtonStyle())
                            } else if pushpullcommand == .pull_remote {
                                Button("Pull") {
                                    showprogressview = true
                                    pull(config: config)
                                }
                                .padding()
                                .buttonStyle(ColorfulButtonStyle())
                            } else {
                                Button("Select") {}
                                    .padding()
                                    .buttonStyle(ColorfulButtonStyle())
                            }
                        }

                        PushPullCommandView(pushpullcommand: $pushpullcommand,
                                            dryrun: $dryrun,
                                            keepdelete: $keepdelete,
                                            config: config)
                            .padding()
                    }

                } else {
                    Spacer()

                    if pushorpull.rsyncpullmax > 0, pushpullcommand == .pull_remote {
                        VStack {
                            ProgressView("",
                                         value: progress,
                                         total: Double(pushorpull.rsyncpullmax))
                                .frame(alignment: .center)
                                .frame(width: 180)

                            HStack {
                                Text("\(Int(pushorpull.rsyncpullmax)): ")
                                    .padding()
                                    .font(.title2)

                                Text("\(Int(progress))")
                                    .padding()
                                    .font(.title2)
                                    .contentTransition(.numericText(countsDown: false))
                                    .animation(.default, value: progress)
                            }
                        }

                    } else if pushorpull.rsyncpushmax > 0, pushpullcommand == .push_local {
                        VStack {
                            ProgressView("",
                                         value: progress,
                                         total: Double(pushorpull.rsyncpushmax))
                                .frame(alignment: .center)
                                .frame(width: 180)

                            HStack {
                                Text("\(Int(pushorpull.rsyncpushmax)): ")
                                    .padding()
                                    .font(.title2)

                                Text("\(Int(progress))")
                                    .padding()
                                    .font(.title2)
                                    .contentTransition(.numericText(countsDown: false))
                                    .animation(.default, value: progress)
                            }
                        }

                    } else {
                        VStack {
                            ProgressView()

                            Text("\(Int(progress))")
                                .font(.title2)
                                .contentTransition(.numericText(countsDown: false))
                                .animation(.default, value: progress)
                        }
                    }

                    Spacer()
                }
            }
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

    // For a verify run, --dry-run
    func push(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: dryrun,
                                                                                           forDisplay: false,
                                                                                           keepdelete: keepdelete)
        /*
         let process = ProcessRsync(arguments: arguments,
                                    config: config,
                                    processtermination: processtermination,
                                    filehandler: filehandler)
         */
        let process = ProcessRsyncAsyncSequence(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination,
                                   filehandler: filehandler)
        process.executeProcess()
    }

    func pull(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: dryrun,
                                                                                              forDisplay: false,
                                                                                              keepdelete: keepdelete)
        /*
         let process = ProcessRsync(arguments: arguments,
                                    config: config,
                                    processtermination: processtermination,
                                    filehandler: filehandler)
         */
        let process = ProcessRsyncAsyncSequence(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination,
                                   filehandler: filehandler)
        process.executeProcess()
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                  config: config)
        } else {
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
        }

        Task {
            remotedatanumbers?.outputfromrsync = await ActorCreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
        }
    }

    func filehandler(count: Int) {
        progress = Double(count)
    }

    func abort() {
        InterruptProcess()
    }
}
