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
        ZStack {
            ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                        configurations: rsyncUIdata.configurations)

            if progressviewshowinfo {
                HStack {
                    ProgressView()

                    Text("\(Int(progress))")
                        .font(.title2)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.default, value: progress)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            if focusaborttask { labelaborttask }
        }
        .onAppear {
            executeAllNoEstimationTasks()
        }
        .onDisappear {
            execute = nil
            if SharedReference.shared.process != nil {
                InterruptProcess()
            }
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

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }
}

extension ExecuteNoEstTasksView {
    func fileHandler(count: Int) {
        progress = count
    }

    func abort() {
        execute = nil
        selecteduuids.removeAll()
        InterruptProcess()
        progressviewshowinfo = false
        noestprogressdetails.reset()
    }

    func executeAllNoEstimationTasks() {
        noestprogressdetails.startExecuteAllTasksNoEstimation()
        if let configurations = rsyncUIdata.configurations {
            execute = Execute.start(profile: rsyncUIdata.profile,
                                    configurations: configurations,
                                    selecteduuids: selecteduuids,
                                    noestprogressdetails: noestprogressdetails,
                                    fileHandler: fileHandler,
                                    updateconfigurations: updateConfigurations)
        }
    }

    func updateConfigurations(_ configurations: [SynchronizeConfiguration]) {
        execute = nil
        rsyncUIdata.configurations = configurations
        progressviewshowinfo = false
        noestprogressdetails.reset()
        executetaskpath.append(Tasks(task: .completedview))
    }
}
