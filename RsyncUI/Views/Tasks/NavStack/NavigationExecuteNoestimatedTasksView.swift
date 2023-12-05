//
//  NavigationExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

struct NavigationExecuteNoestimatedTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    // Must be stateobject
    @StateObject private var executeprogressdetails = ExecuteProgressDetails()
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

            if executeprogressdetails.executeasyncnoestimationcompleted == true { labelcompleted }
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

extension NavigationExecuteNoestimatedTasksView {
    func completed() {
        reload = true
        executeprogressdetails.resetcounts()
        progressviewshowinfo = false
    }

    func abort() {
        selecteduuids.removeAll()
        executeprogressdetails.resetcounts()
        _ = InterruptProcess()
        reload = true
        progressviewshowinfo = false
    }

    func executeallnotestimatedtasks() async {
        Logger.process.info("ExecuteallNOtestimatedtasks() : \(selecteduuids, privacy: .public)")
        executeprogressdetails.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteTasksAsync(profile: rsyncUIdata.profile,
                              configurations: rsyncUIdata,
                              executeprogressdetails: executeprogressdetails,
                              uuids: selecteduuids,
                              filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}
