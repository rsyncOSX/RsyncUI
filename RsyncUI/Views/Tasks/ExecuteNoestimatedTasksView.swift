//
//  ExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 31/01/2023.
//

import SwiftUI

struct ExecuteNoestimatedTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    // These two objects keeps track of the state and collects
    // the estimated values.
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showcompleted: Bool
    @Binding var showexecutenoestimateview: Bool

    @State private var inwork: Int = -1
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
                inwork: $inwork,
                filterstring: $filterstring,
                reload: $reload,
                confirmdelete: $confirmdelete,
                reloadtasksviewlist: $reloadtasksviewlist,
                doubleclick: $doubleclick
            )

            // When completed
            if inprogresscountmultipletask.executeasyncnoestimationcompleted == true { labelcompleted }

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
        inwork = -1
        reload = true
        showcompleted = true
        inprogresscountmultipletask.resetcounts()
        progressviewshowinfo = false
        inprogresscountmultipletask.estimateasync = false
        showexecutenoestimateview = false
    }

    func abort() {
        selecteduuids.removeAll()
        inprogresscountmultipletask.resetcounts()
        _ = InterruptProcess()
        inwork = -1
        reload = true
        progressviewshowinfo = false
        showexecutenoestimateview = false
    }

    func executeallnotestimatedtasks() async {
        inprogresscountmultipletask.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteAlltasksAsync(profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata,
                                 updateinprogresscount: inprogresscountmultipletask,
                                 uuids: selecteduuids,
                                 filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}
