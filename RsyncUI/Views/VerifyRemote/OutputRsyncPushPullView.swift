//
//  OutputRsyncPushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2024.
//

import SwiftUI

struct OutputRsyncPushPullView: View {
    @Binding var verifynavigation: [VerifyTasks]

    @State private var progress = false
    @State private var remotedatanumbers: RemoteDataNumbers?

    @State private var pushpullcommand = PushPullCommand.push_local
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    let config: SynchronizeConfiguration
    let profile: String?

    var body: some View {
        HStack {
            if let remotedatanumbers {
                DetailsView(remotedatanumbers: remotedatanumbers)
            } else {
                ZStack {
                    VStack {
                        ListofTasksLightView(selecteduuids: $selecteduuids,
                                             profile: profile,
                                             configurations: configurations)
                            .frame(maxWidth: .infinity)

                        Spacer()

                        HStack {
                            if pushpullcommand == .push_local {
                                Button("Push") {
                                    progress = true
                                    push(config: config)
                                }
                            } else {
                                Button("Pull") {
                                    progress = true
                                    pull(config: config)
                                }
                            }

                            PushPullCommandView(pushpullcommand: $pushpullcommand, config: config)
                        }
                    }

                    if progress {
                        Spacer()

                        ProgressView()

                        Spacer()
                    }
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

    var configurations: [SynchronizeConfiguration] {
        var configurations = [SynchronizeConfiguration]()
        configurations.append(config)
        return configurations
    }

    // For a verify run, --dry-run
    func push(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: true,
                                                                                           forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func pull(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                              forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = Array(stringoutputfromrsync[stringoutputfromrsync.count - 20 ..< stringoutputfromrsync.count])
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                  config: config)
        } else {
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: config)
        }

        Task {
            remotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
        }
    }

    func abort() {
        InterruptProcess()
    }
}
