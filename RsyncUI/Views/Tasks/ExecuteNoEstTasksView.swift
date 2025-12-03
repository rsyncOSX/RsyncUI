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
    // Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]

    @State private var noestprogressdetails = NoEstProgressDetails()
    @State private var progressviewshowinfo: Bool = true
    @State private var focusaborttask: Bool = false

    @State private var progress: Int = 0

    var body: some View {
        ZStack {
            ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                        configurations: rsyncUIdata.configurations)

            if progressviewshowinfo {
                VStack {
                    ProgressView()

                    Text("\(Int(progress))")
                        .font(.title2)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.default, value: progress)
                }
            }
            if focusaborttask { labelaborttask }
        }
        .onAppear {
            executeallnoestimationtasks()
        }
        .onDisappear {
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
                    Image(systemName: "stop.fill")
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
    func filehandler(count: Int) {
        progress = count
    }

    func abort() {
        selecteduuids.removeAll()
        InterruptProcess()
        progressviewshowinfo = false
        noestprogressdetails.reset()
    }

    func executeallnoestimationtasks() {
        noestprogressdetails.startexecutealltasksnoestimation()
        if let configurations = rsyncUIdata.configurations {
            Execute(profile: rsyncUIdata.profile,
                            configurations: configurations,
                            selecteduuids: selecteduuids,
                            noestprogressdetails: noestprogressdetails,
                            filehandler: filehandler,
                            updateconfigurations: updateconfigurations)
        }
    }

    func updateconfigurations(_ configurations: [SynchronizeConfiguration]) {
        rsyncUIdata.configurations = configurations
        progressviewshowinfo = false
        noestprogressdetails.reset()
        executetaskpath.append(Tasks(task: .completedview))
    }
}
