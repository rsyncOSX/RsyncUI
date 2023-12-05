//
//  ExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 31/01/2023.
//

import OSLog
import SwiftUI

struct ExecuteNoestimatedTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showexecutenoestimateview: Bool

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
        executeprogressdetails.resetcounts()
        progressviewshowinfo = false
        showexecutenoestimateview = false
    }

    func abort() {
        selecteduuids.removeAll()
        executeprogressdetails.resetcounts()
        _ = InterruptProcess()
        reload = true
        progressviewshowinfo = false
        showexecutenoestimateview = false
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
