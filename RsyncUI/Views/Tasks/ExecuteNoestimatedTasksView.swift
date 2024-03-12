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
    @State private var executeasyncnoestimation = ExecuteAsyncNoEstimation()
    @State private var filterstring: String = ""
    @State private var progressviewshowinfo: Bool = true
    @State private var executetasks: ExecuteTasksNOEstimation?
    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            ListofTasksView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                profile: rsyncUIdata.profile,
                configurations: rsyncUIdata.configurations ?? []
            )

            if executeasyncnoestimation.executeasyncnoestimationcompleted == true { labelcompleted }
            if progressviewshowinfo { ProgressView() }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            executeallnoestimationtasks()
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

    // When status execution is .completed, present label and execute completed.
    var labelcompleted: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                completed()
                path.removeAll()
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
    func completed() {
        progressviewshowinfo = false
        executeasyncnoestimation.reset()
    }

    func abort() {
        selecteduuids.removeAll()
        _ = InterruptProcess()
        progressviewshowinfo = false
        executeasyncnoestimation.reset()
    }

    func executeallnoestimationtasks() {
        Logger.process.info("ExecuteallNOtestimatedtasks() : \(selecteduuids, privacy: .public)")
        executeasyncnoestimation.startasyncexecutealltasksnoestimation()
        if let configurations = rsyncUIdata.configurations {
            executetasks =
                ExecuteTasksNOEstimation(profile: rsyncUIdata.profile,
                                         rsyncuiconfigurations: configurations,
                                         executeasyncnoestimation: executeasyncnoestimation,
                                         uuids: selecteduuids,
                                         filter: filterstring,
                                         updateconfigurations: updateconfigurations)
            executetasks?.startexecution()
        }
    }

    func updateconfigurations(_ configurations: [SynchronizeConfiguration]) {
        rsyncUIdata.configurations = configurations
    }
}
