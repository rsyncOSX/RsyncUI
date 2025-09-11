//
//  VerifyTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2025.
//

import SwiftUI

struct VerifyTasks: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var remotedatanumbers: RemoteDataNumbers?
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    // Present arguments view
    @State private var presentestimates: Bool = false
    // Estimating
    @State private var estimating: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    ListofTasksAddView(rsyncUIdata: rsyncUIdata,
                                       selecteduuids: $selecteduuids)
                        .onChange(of: selecteduuids) {
                            if let configurations = rsyncUIdata.configurations {
                                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                    selectedconfig = configurations[index]

                                } else {
                                    selectedconfig = nil
                                }
                            }
                        }

                    if estimating {
                        ProgressView()
                    }
                }

                Text("Verify task always include the --dry-run parameter.")
                    .foregroundColor(.blue)
                    .font(.title)

                HStack {
                    Text("Select a task and select the ")
                        .foregroundColor(.blue)
                        .font(.title2)

                    Text(Image(systemName: "play.fill"))
                        .foregroundColor(.blue)
                        .font(.title2)

                    Text(" on the toolbar to verify a task.")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .toolbar(content: {
                if selectedconfig != nil,
                   selectedconfig?.task != SharedReference.shared.halted
                {
                    ToolbarItem {
                        Button {
                            if let selectedconfig {
                                estimating = true
                                verify(config: selectedconfig)
                            }
                        } label: {
                            Image(systemName: "play.fill")
                                .foregroundColor(.blue)
                        }
                        .help("Verify task")
                    }
                }

                if selectedconfig != nil,
                   selectedconfig?.task != SharedReference.shared.halted
                {
                    ToolbarItem {
                        Button {
                            abort()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .help("Abort (⌘K)")
                    }
                }

            })
            .navigationTitle("Verify tasks - dry-run parameter is enabled")
            .navigationDestination(isPresented: $presentestimates) {
                if let remotedatanumbers {
                    DetailsView(remotedatanumbers: remotedatanumbers)
                }
            }
        }
    }

    // For a verify run, --dry-run
    func verify(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                  forDisplay: false)
        if SharedReference.shared.rsyncversion3 {
            let process = ProcessRsyncVer3x(arguments: arguments,
                                            config: config,
                                            processtermination: processtermination)
            process.executeProcess()
        } else {
            let process = ProcessRsyncOpenrsync(arguments: arguments,
                                            config: config,
                                            processtermination: processtermination)
            process.executeProcess()
        }
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        estimating = false

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                  config: selectedconfig)
        } else {
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: selectedconfig)
        }

        Task {
            remotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)
            presentestimates = true
        }
    }

    func abort() {
        InterruptProcess()
    }
}
