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
                                ShortcutsApprovalStatusView(config: selectedconfig)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: selecteduuids) {
            presentestimates = false
            remotedatanumbers = nil
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
                            Label("Verify task", systemImage: "play.fill")
                                .labelStyle(.iconOnly)
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
                            Label("Abort", systemImage: "stop.fill")
                                .labelStyle(.iconOnly)
                        }
                        .help("Abort (⌘K)")
                    }
                }

                if let selectedconfig,
                   selectedconfig.task != SharedReference.shared.halted {
                    let allowed = selectedconfig.isAllowedInShortcuts
                    // Allowing needs a completed verify run of the current settings
                    let canAllow = presentestimates && remotedatanumbers?.hasUsableStatistics == true
                    ToolbarItem {
                        Button {
                            setShortcutsApproval(selectedconfig, allowed: !allowed)
                        } label: {
                            ShortcutsApprovalToolbarLabel(allowed: allowed)
                        }
                        .disabled(!allowed && !canAllow)
                        .help(allowed
                            ? "Allowed in Shortcuts. Click to revoke."
                            : canAllow
                            ? "Allow Shortcuts to synchronize this task without opening RsyncUI"
                            : "Verify the task first, then click to allow it in Shortcuts.")
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
                Task { @MainActor in
                    processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
                }
            },
            cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
        )

        guard SharedReference.shared.norsync == false, config.task != SharedReference.shared.halted, let streamingHandlers, let arguments else { return }

        itemizechanges = arguments.contains("--itemize-changes")

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

    @MainActor
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

        remotedatanumbers?.outputfromrsync = CreateOutputforView().createOutputForView(stringoutputfromrsync)
        presentestimates = true
        // Release streaming references to avoid retain cycles
        activeStreamingProcess = nil
        streamingHandlers = nil
    }

    func setShortcutsApproval(_ config: SynchronizeConfiguration, allowed: Bool) {
        Task { @MainActor in
            let update = UpdateConfigurations(profile: rsyncUIdata.profile,
                                              configurations: rsyncUIdata.configurations)
            await update.setShortcutsApproval(hiddenID: config.hiddenID, allowed: allowed)
            rsyncUIdata.configurations = update.configurations
            selectedconfig = update.configurations?.first { $0.hiddenID == config.hiddenID }
        }
    }

    func abort() {
        presentestimates = false
        remotedatanumbers = nil
        InterruptProcess()
    }
}

/// Whether Shortcuts may synchronize the task, and how to allow it.
struct ShortcutsApprovalStatusView: View {
    let config: SynchronizeConfiguration

    var body: some View {
        if config.isAllowedInShortcuts {
            Label("Allowed in Shortcuts", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if config.shortcutsapproval != nil {
            Label("The task has changed since it was allowed in Shortcuts. Verify it again to allow it.",
                  systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        } else {
            Label("Not allowed in Shortcuts. Verify the task, then click Not allowed in Shortcuts in the toolbar to allow it.",
                  systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
        }
    }
}

/// Toolbar toggle: green checkmark while allowed, red cross while not.
struct ShortcutsApprovalToolbarLabel: View {
    let allowed: Bool

    var body: some View {
        Label {
            Text(allowed ? "Allowed in Shortcuts" : "Not allowed in Shortcuts")
        } icon: {
            Image(systemName: allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, allowed ? Color.green : Color.red)
        }
        .labelStyle(.titleAndIcon)
    }
}
