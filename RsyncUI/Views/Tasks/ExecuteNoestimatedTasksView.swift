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

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showcompleted: Bool
    @Binding var showexecutenoestimateview: Bool

    @State private var inwork: Int = -1
    @State private var searchText: String = ""
    @State private var progressviewshowinfo: Bool = true

    @State private var executealltasksasync: ExecuteAlltasksAsync?

    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            ListofTasksProgress(selectedconfig: $selectedconfig,
                                selecteduuids: $selecteduuids,
                                inwork: $inwork,
                                searchText: $searchText,
                                reload: $reload,
                                confirmdelete: $confirmdelete)

            // When completed
            if inprogresscountmultipletask.executeasyncnoestimationcompleted == true { labelcompleted }

            if progressviewshowinfo { progressviewexecuteasync }
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

    var progressviewexecuteasync: some View {
        ProgressView()
            .frame(width: 50.0, height: 50.0)
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
        selectedconfig = nil
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
            ExecuteAlltasksAsync(profile: rsyncUIdata.configurationsfromstore?.profile,
                                 configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                 updateinprogresscount: inprogresscountmultipletask,
                                 uuids: selecteduuids,
                                 filter: searchText)
        await executealltasksasync?.startexecution()
    }
}
