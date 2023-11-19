//
//  NavigationExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

@available(macOS 14.0, *)
struct NavigationExecuteNoestimatedTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @State private var estimatingprogresscount = EstimateProgressDetails14()
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]
    @State private var filterstring: String = ""
    @State private var progressviewshowinfo: Bool = true
    @State private var executealltasksasync: ExecuteTasksAsync14?
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

@available(macOS 14.0, *)
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
        Logger.process.info("ExecuteallNOtestimatedtasks() : \(selecteduuids)")
        estimatingprogresscount.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteTasksAsync14(profile: rsyncUIdata.profile,
                                configurations: rsyncUIdata,
                                updateinprogresscount: estimatingprogresscount,
                                uuids: selecteduuids,
                                filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}
