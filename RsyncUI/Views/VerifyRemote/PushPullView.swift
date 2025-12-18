//
//  PushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import OSLog
import RsyncProcessStreaming
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

    // Streaming strong references
    @State private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

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
                                    pushpullcommand = .pushLocal
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
                                    pushpullcommand = .pullRemote
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
            pullRemote(config: config)
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
    func pullRemote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                              forDisplay: false,
                                                                                              keepdelete: true)

        streamingHandlers = CreateStreamingHandlers().createHandlers(
            fileHandler: { _ in },
            processTermination: { output, hiddenID in
                pullProcessTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
            }
        )

        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }
        guard let arguments else { return }
        guard let streamingHandlers else { return }

        let process = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: streamingHandlers,
            useFileHandler: false
        )
        do {
            try process.executeProcess()
            activeStreamingProcess = process
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    // For check remote, pull remote data
    func pushRemote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremotewithparameters(dryRun: true,
                                                                                                         forDisplay: false,
                                                                                                         keepdelete: true)
        streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
            fileHandler: { _ in },
            processTermination: { output, hiddenID in
                pushProcessTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
            },
            cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
        )

        guard let arguments else { return }
        guard let streamingHandlers else { return }

        let process = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: streamingHandlers,
            useFileHandler: false
        )
        do {
            try process.executeProcess()
            activeStreamingProcess = process
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    func pullProcessTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        DispatchQueue.main.async {
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
        }
        if isadjusted == false {
            Task.detached { [stringoutputfromrsync] in
                let out = await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
                await MainActor.run { pullremotedatanumbers?.outputfromrsync = out }
            }
        }
        // Release current streaming before next task
        activeStreamingProcess = nil
        streamingHandlers = nil
        // Then do a synchronize task, adjusted for push vs pull
        pushRemote(config: config)
    }

    // This is a normal synchronize task, dry-run = true
    func pushProcessTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        DispatchQueue.main.async {
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
        }

        if isadjusted {
            // Adjust both outputs
            pushorpull.adjustoutput()
            let adjustedPull = pushorpull.adjustedpull
            let adjustedPush = pushorpull.adjustedpush
            Task.detached { [adjustedPull, adjustedPush] in
                async let outPull = ActorCreateOutputforView().createOutputForView(adjustedPull)
                async let outPush = ActorCreateOutputforView().createOutputForView(adjustedPush)
                let (pull, push) = await (outPull, outPush)
                await MainActor.run {
                    pullremotedatanumbers?.outputfromrsync = pull
                    pushremotedatanumbers?.outputfromrsync = push
                }
            }
        } else {
            Task.detached { [stringoutputfromrsync] in
                let out = await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
                await MainActor.run { pushremotedatanumbers?.outputfromrsync = out }
            }
        }
        // Final cleanup
        activeStreamingProcess = nil
        streamingHandlers = nil
    }

    func abort() {
        InterruptProcess()
    }
}
