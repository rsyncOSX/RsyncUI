//
//  ExecutePushPullView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2024.
//

import SwiftUI

struct ExecutePushPullView: View {
    @Binding var verifynavigation: [VerifyTasks]

    @State private var progress = false
    @State private var remotedatanumbers: RemoteDataNumbers?

    @State private var pushpullcommand = PushPullCommand.none
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    // Alert button
    @State private var showingAlert = false
    @State private var dryrun: Bool = true

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

                        VStack {
                            HStack {
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
                                }

                                if pushpullcommand != .none {
                                    Toggle("--dry-run", isOn: $dryrun)
                                        .toggleStyle(.switch)
                                }
                            }

                            PushPullCommandView(pushpullcommand: $pushpullcommand, dryrun: $dryrun, config: config)
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
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Switch dry-run mode?"),
                primaryButton: .default(Text("ON")) {
                    // path.append(Tasks(task: .executenoestimatetasksview))
                },
                secondaryButton: .cancel {
                    dryrun = true
                }
            )
        }
        .onChange(of: dryrun) {
            showingAlert = !dryrun
        }
    }

    var configurations: [SynchronizeConfiguration] {
        var configurations = [SynchronizeConfiguration]()
        configurations.append(config)
        return configurations
    }

    // For a verify run, --dry-run
    func push(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: dryrun,
                                                                                           forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func pull(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: dryrun,
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
