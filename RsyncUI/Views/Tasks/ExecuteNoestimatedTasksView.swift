//
//  ExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

struct ExecuteNoestimatedTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    // Must be stateobject
    @State private var noestimationprogressdetails = NoEstimationProgressDetails()
    @State private var progressviewshowinfo: Bool = true
    @State private var executetasks: ExecuteTasksNOEstimation?
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                        configurations: rsyncUIdata.configurations)

            if progressviewshowinfo { ProgressView() }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            executeallnoestimationtasks()
        })
        .onDisappear(perform: {
            if SharedReference.shared.process != nil {
                InterruptProcess()
            }
        })
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
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

extension ExecuteNoestimatedTasksView {
    func abort() {
        selecteduuids.removeAll()
        InterruptProcess()
        progressviewshowinfo = false
        noestimationprogressdetails.reset()
    }

    func executeallnoestimationtasks() {
        Logger.process.info("executeallnoestimationtasks(): \(selecteduuids, privacy: .public)")
        noestimationprogressdetails.startexecutealltasksnoestimation()
        if let configurations = rsyncUIdata.configurations {
            executetasks =
                ExecuteTasksNOEstimation(profile: rsyncUIdata.profile,
                                         rsyncuiconfigurations: configurations,
                                         noestimationprogressdetails: noestimationprogressdetails,
                                         selecteduuids: selecteduuids,
                                         updateconfigurations: updateconfigurations)
            executetasks?.startexecution()
        }
    }

    func updateconfigurations(_ configurations: [SynchronizeConfiguration]) {
        Logger.process.info("Updateconfigurations() in memory\nReset data and return to MAIN THREAD task view")
        rsyncUIdata.configurations = configurations
        progressviewshowinfo = false
        noestimationprogressdetails.reset()
        path.append(Tasks(task: .completedview))
    }
}
