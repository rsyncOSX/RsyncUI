//
//  NavigationExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftUI

struct NavigationExecuteNoestimatedTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var estimatingprogresscount = EstimateProgressDetails()
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]
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

            if estimatingprogresscount.executeasyncnoestimationcompleted == true { labelcompleted }
            if progressviewshowinfo { AlertToast(displayMode: .alert, type: .loading) }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            Task {
                await executeallnotestimatedtasks()
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

extension NavigationExecuteNoestimatedTasksView {
    func completed() {
        reload = true
        estimatingprogresscount.resetcounts()
        progressviewshowinfo = false
        estimatingprogresscount.estimatealltasksasync = false
    }

    func abort() {
        selecteduuids.removeAll()
        estimatingprogresscount.resetcounts()
        _ = InterruptProcess()
        reload = true
        progressviewshowinfo = false
    }

    func executeallnotestimatedtasks() async {
        estimatingprogresscount.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteTasksAsync(profile: rsyncUIdata.profile,
                              configurations: rsyncUIdata,
                              updateinprogresscount: estimatingprogresscount,
                              uuids: selecteduuids,
                              filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}
