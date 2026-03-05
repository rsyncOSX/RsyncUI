//
//  VerifyTaskTabView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/03/2026.
//

//
//  VerifyTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2025.
//

import OSLog
import RsyncProcessStreaming
import SwiftUI

struct VerifyTaskTabView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var remotedatanumbers: RemoteDataNumbers?
    @State private var selectedconfig: SynchronizeConfiguration?
    /// Present arguments view
    @State private var presentestimates: Bool = false
    /// Estimating
    @State private var estimating: Bool = false
    // Streaming strong references
    @State private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?
    /// Show Inspector view
    @State var showinspector: Bool = false
    /// itemizechanges
    @State private var itemizechanges: Bool = false

    var body: some View {
        VStack {
            if presentestimates, let remotedatanumbers {
                DetailsView(remotedatanumbers: remotedatanumbers, itemizechanges: remotedatanumbers.itemizechanges)
            } else {
                ZStack {
                    if estimating {
                        ProgressView()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading) {
                            if let selectedconfig {
                                RsyncCommandView(config: selectedconfig)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: selecteduuids) {
            if let configurations = rsyncUIdata.configurations {
                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                    selectedconfig = configurations[index]
                    showinspector = true
                } else {
                    selectedconfig = nil
                    showinspector = false
                }
            }
        }
        .toolbar(content: {
            if selectedTab == .verifytask {
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
            }
        })
        .onAppear {
            if selecteduuids.count > 0 {
                if let configurations = rsyncUIdata.configurations {
                    if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                        selectedconfig = configurations[index]
                        showinspector = true
                    } else {
                        selectedconfig = nil
                        showinspector = false
                    }
                }
            }
            
        }
        .padding()
    }

    /// For a verify run, --dry-run using streaming
    func verify(config: SynchronizeConfiguration) {
        showinspector = false
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

        itemizechanges = arguments.contains("--itemize-changes") && arguments.contains("--update")

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
        remotedatanumbers?.itemizechanges = itemizechanges

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
