//
//  ExecuteNoEstTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

struct ExecuteNoEstTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<UUID>
    /// Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]

    @State private var noestprogressdetails = NoEstProgressDetails()
    @State private var progressviewshowinfo: Bool = true
    @State private var focusaborttask: Bool = false

    @State private var progress: Int = 0
    @State private var execute: Execute?

    var body: some View {
        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                        configurations: rsyncUIdata.configurations)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                if progressviewshowinfo {
                    ProgressView("Synchronizing tasks…")
                    Text("Files processed: \(progress.formatted())")
                        .monospacedDigit()
                }
                Spacer()
            }
            .controlSize(.small)
            .padding()
            .background(.bar)
        }
        .onChange(of: focusaborttask) {
            guard focusaborttask else { return }
            focusaborttask = false
            abort()
        }
        .onAppear {
            executeAllNoEstimationTasks()
        }
        .onDisappear {
            execute?.cancel()
            execute = nil
            rsyncUIdata.executetasksinprogress = false
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Label("Abort", systemImage: "stop.fill")
                        .labelStyle(.iconOnly)
                }
                .help("Abort (⌘K)")
            }
        })
    }

}

extension ExecuteNoEstTasksView {
    func fileHandler(count: Int) {
        progress = count
    }

    func abort() {
        execute?.cancel()
        execute = nil
        selecteduuids.removeAll()
        progressviewshowinfo = false
        noestprogressdetails.reset()
        rsyncUIdata.executetasksinprogress = false
        executetaskpath.removeAll()
    }

    func executeAllNoEstimationTasks() {
        noestprogressdetails.startExecuteAllTasksNoEstimation()
        if let configurations = rsyncUIdata.configurations {
            rsyncUIdata.executetasksinprogress = true
            execute = Execute.start(profile: rsyncUIdata.profile,
                                    configurations: configurations,
                                    selecteduuids: selecteduuids,
                                    noestprogressdetails: noestprogressdetails,
                                    fileHandler: fileHandler,
                                    updateconfigurations: updateConfigurations)
        }
    }

    func updateConfigurations(_ configurations: [SynchronizeConfiguration], outcome: StreamingProcessOutcome) {
        rsyncUIdata.configurations = configurations
        guard outcome != .cancelled else { return }
        execute = nil
        progressviewshowinfo = false
        noestprogressdetails.reset()
        rsyncUIdata.executetasksinprogress = false
        if outcome == .cancelled {
            return
        }
        if outcome == .success {
            executetaskpath.append(Tasks(task: .completedview))
        } else {
            executetaskpath.removeAll()
        }
    }
}
