//
//  ExecutePushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2024.
//

import RsyncProcessStreaming
import SwiftUI

struct ExecutePushPullView: View {
    @Binding var pushorpull: ObservableVerifyRemotePushPull

    @State private var showprogressview = false
    @State private var remotedatanumbers: RemoteDataNumbers?
    @Binding var pushpullcommand: PushPullCommand

    @State private var dryrun: Bool = true
    @State private var keepdelete: Bool = true

    @State private var progress: Double = 0
    @State private var max: Double = 0

    // Streaming strong references
    @State private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

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

                            if pushpullcommand == .pushLocal {
                                ConditionalGlassButton(
                                    systemImage: "arrowshape.right.fill",
                                    helpText: "Push to remote"
                                ) {
                                    showprogressview = true
                                    push(config: config)
                                }
                            } else if pushpullcommand == .pullRemote {
                                ConditionalGlassButton(
                                    systemImage: "arrowshape.left.fill",
                                    helpText: "Pull from remote"
                                ) {
                                    showprogressview = true
                                    pull(config: config)
                                }
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

                    if pushorpull.rsyncpullmax > 0, pushpullcommand == .pullRemote {
                        HStack {
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    } else if pushorpull.rsyncpushmax > 0, pushpullcommand == .pushLocal {
                        HStack {
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    } else {
                        SynchronizeProgressView(max: max, progress: progress, statusText: "Synchronizing...")
                    }

                    Spacer()
                }
            }
        }
        .toolbar(content: {
            ToolbarItem {
                ConditionalGlassButton(
                    systemImage: "stop.fill",
                    helpText: "Abort"
                ) {
                    abort()
                }
            }
        })
    }

    // For a verify run, --dry-run
    func push(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremotewithparameters(dryRun:
            dryrun,
            forDisplay: false,
            keepdelete: keepdelete)

        streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
            fileHandler: fileHandler,
            processTermination: { output, hiddenID in
                processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
            },
            cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
        )

        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }
        guard let arguments else { return }
        guard let streamingHandlers else { return }

        let process = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: streamingHandlers,
            useFileHandler: true
        )
        do {
            try process.executeProcess()
            activeStreamingProcess = process
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    func pull(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: dryrun,
                                                                                              forDisplay: false,
                                                                                              keepdelete: keepdelete)

        streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
            fileHandler: fileHandler,
            processTermination: { output, hiddenID in
                processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
            },
            cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
        )
        guard let arguments else { return }
        guard let streamingHandlers else { return }

        let process = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: streamingHandlers,
            useFileHandler: true
        )
        do {
            try process.executeProcess()
            activeStreamingProcess = process
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        DispatchQueue.main.async {
            showprogressview = false

            let lines = stringoutputfromrsync?.count ?? 0
            if dryrun {
                max = Double(lines)
            }

            if lines > SharedReference.shared.alerttagginglines, let stringoutputfromrsync {
                let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
                remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                      config: config)
            } else {
                remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                      config: config)
            }
        }

        Task.detached { [stringoutputfromrsync] in
            let out = await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
            await MainActor.run { remotedatanumbers?.outputfromrsync = out }
        }
        // Release streaming references to avoid retain cycles
        activeStreamingProcess = nil
        streamingHandlers = nil
    }

    func fileHandler(count: Int) {
        DispatchQueue.main.async { progress = Double(count) }
    }

    func abort() {
        InterruptProcess()
    }
}
