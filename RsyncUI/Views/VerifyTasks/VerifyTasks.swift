//
//  VerifyTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2025.
//

import OSLog
import RsyncProcessStreaming
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
    // Show warning
    @State private var showmessage: Bool = true
    // Streaming strong references
    @State private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

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
                    
                    if selecteduuids.count == 1 {
                        
                    }

                    if estimating {
                        ProgressView()
                    }

                    if showmessage {
                        Text("Verify task **always** include the --dry-run parameter")
                            .foregroundColor(.blue)
                            .font(.title)
                            .onAppear {
                                Task {
                                    try await Task.sleep(seconds: 3)
                                    showmessage = false
                                }
                            }
                    }
                }

                HStack {
                    Text("Select a task and select the ")

                    Text(Image(systemName: "play.fill"))

                    Text(" on the toolbar to verify a task")
                }
            }
            .toolbar(content: {
                if selectedconfig != nil,
                   selectedconfig?.task != SharedReference.shared.halted {
                    ToolbarItem {
                        Button {
                            if let selectedconfig {
                                estimating = true
                                verify(config: selectedconfig)
                            }
                        } label: {
                            Image(systemName: "play.fill")
                        }
                        .help("Verify task")
                    }
                }

                if selectedconfig != nil,
                   selectedconfig?.task != SharedReference.shared.halted {
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

    // For a verify run, --dry-run using streaming
    func verify(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: true,
                                                                                  forDisplay: false)

        streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
            fileHandler: { _ in },
            processTermination: { output, hiddenID in
                processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
            },
            cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
        )

        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }
        guard let streamingHandlers else { return }
        guard let arguments else { return }

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

    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        estimating = false

        let lines = stringoutputfromrsync?.count ?? 0
        let threshold = SharedReference.shared.alerttagginglines
        let prepared: [String]? = if lines > threshold, let data = stringoutputfromrsync {
            PrepareOutputFromRsync().prepareOutputFromRsync(data)
        } else {
            stringoutputfromrsync
        }

        remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: prepared,
                                              config: selectedconfig)

        Task { @MainActor in
            remotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
            presentestimates = true
        }
        // Release streaming references to avoid retain cycles
        activeStreamingProcess = nil
        streamingHandlers = nil
    }

    func abort() {
        InterruptProcess()
    }
}
