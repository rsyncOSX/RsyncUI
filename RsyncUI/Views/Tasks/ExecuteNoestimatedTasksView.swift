//
//  ExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

struct ExecuteNoestimatedTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    // Must be stateobject
    @State private var executeasyncnoestimation = ExecuteAsyncNoEstimation()
    @State private var filterstring: String = ""
    @State private var progressviewshowinfo: Bool = true
    @State private var executealltasksasync: ExecuteTasksAsync?
    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            ListofTasksView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring
            )

            if executeasyncnoestimation.executeasyncnoestimationcompleted == true { labelcompleted }
            if progressviewshowinfo { AlertToast(displayMode: .alert, type: .loading) }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            Task {
                await executeallnoestimationtasks()
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
        reload = true
        progressviewshowinfo = false
        executeasyncnoestimation.reset()
    }

    func abort() {
        selecteduuids.removeAll()
        _ = InterruptProcess()
        reload = true
        progressviewshowinfo = false
        executeasyncnoestimation.reset()
    }

    func executeallnoestimationtasks() async {
        Logger.process.info("ExecuteallNOtestimatedtasks() : \(selecteduuids, privacy: .public)")
        executeasyncnoestimation.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteTasksAsync(profile: rsyncUIdata.profile,
                              configurations: rsyncUIdata,
                              executeasyncnoestimation: executeasyncnoestimation,
                              uuids: selecteduuids,
                              filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}
