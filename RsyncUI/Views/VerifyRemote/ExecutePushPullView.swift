//
//  ExecutePushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2024.
//

import SwiftUI

struct ExecutePushPullView: View {
    @State private var progress = false
    @State private var remotedatanumbers: RemoteDataNumbers?
    @State private var pushpullcommand = PushPullCommand.none

    @State private var dryrun: Bool = true
    @State private var removedelete: Bool = true

    let config: SynchronizeConfiguration

    var body: some View {
        HStack {
            if let remotedatanumbers {
                DetailsView(remotedatanumbers: remotedatanumbers)
            } else {
                ZStack {
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

                                Toggle("--delete, ON removed", isOn: $removedelete)
                                    .toggleStyle(.switch)
                                    .onTapGesture {
                                        withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                            removedelete.toggle()
                                        }
                                    }
                                    .help("Remove the delete parameter, default is true?")
                            }

                            if pushpullcommand == .push_local {
                                Button("Push") {
                                    progress = true
                                    push(config: config)
                                }
                                .padding()
                                .buttonStyle(ColorfulButtonStyle())
                            } else if pushpullcommand == .pull_remote {
                                Button("Pull") {
                                    progress = true
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

                        PushPullCommandView(pushpullcommand: $pushpullcommand, dryrun: $dryrun, removedelete: $removedelete, config: config)
                            .padding()
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

    // For a verify run, --dry-run
    func push(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: dryrun,
                                                                                           forDisplay: false,
                                                                                           removedelete: removedelete)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func pull(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: dryrun,
                                                                                              forDisplay: false,
                                                                                              removedelete: removedelete)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
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
