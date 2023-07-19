//
//  ExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 31/01/2023.
//

import SwiftUI

struct ExecuteNoestimatedTasksView: View {
    @SwiftUI.Environment(RsyncUIconfigurations.self) private var rsyncUIdata
    @State private var estimatingprogresscount = EstimatingProgressCount()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showcompleted: Bool
    @Binding var showexecutenoestimateview: Bool

    @State private var filterstring: String = ""
    @State private var progressviewshowinfo: Bool = true

    @State private var executealltasksasync: ExecuteAlltasksAsync?

    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    @State private var reloadtasksviewlist = false
    // Double click, only for macOS13 and later
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            ListofTasksView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                confirmdelete: $confirmdelete,
                reloadtasksviewlist: $reloadtasksviewlist,
                doubleclick: $doubleclick
            )

            // When completed
            if estimatingprogresscount.executeasyncnoestimationcompleted == true { labelcompleted }

            if progressviewshowinfo { AlertToast(displayMode: .alert, type: .loading) }
        }
        HStack {
            Spacer()

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .onAppear(perform: {
            Task {
                await executeallnotestimatedtasks()
            }
        })
        .focusedSceneValue(\.aborttask, $focusaborttask)
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
        showcompleted = true
        estimatingprogresscount.resetcounts()
        progressviewshowinfo = false
        estimatingprogresscount.estimateasync = false
        showexecutenoestimateview = false
    }

    func abort() {
        selecteduuids.removeAll()
        estimatingprogresscount.resetcounts()
        _ = InterruptProcess()
        reload = true
        progressviewshowinfo = false
        showexecutenoestimateview = false
    }

    func executeallnotestimatedtasks() async {
        estimatingprogresscount.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteAlltasksAsync(profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata,
                                 updateinprogresscount: estimatingprogresscount,
                                 uuids: selecteduuids,
                                 filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}
