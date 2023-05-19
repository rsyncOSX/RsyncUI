//
//  ExecuteNoestimateOneTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/02/2023.
//

import SwiftUI

struct ExecuteNoestimateOneTaskView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    // These two objects keeps track of the state and collects
    // the estimated values.
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showcompleted: Bool
    @Binding var showexecutenoestiamteonetask: Bool

    @State private var inwork: Int = -1
    @State private var filterstring: String = ""
    @State private var progressviewshowinfo: Bool = true

    @State private var executeonetaskasync: ExecuteOnetaskAsync?

    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            TableListofTasksProgress(
                selecteduuids: $selecteduuids,
                inwork: $inwork,
                filterstring: $filterstring,
                reload: $reload,
                confirmdelete: $confirmdelete
            )

            // When completed
            if inprogresscountmultipletask.executeasyncnoestimationcompleted == true { labelcompleted }

            if progressviewshowinfo { ProgressView() }
        }
        HStack {
            Spacer()

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .onAppear(perform: {
            Task {
                await executeonenotestimatedtask()
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

extension ExecuteNoestimateOneTaskView {
    func completed() {
        inwork = -1
        reload = true
        showcompleted = true
        inprogresscountmultipletask.resetcounts()
        selectedconfig = nil
        progressviewshowinfo = false
        inprogresscountmultipletask.estimateasync = false
        showexecutenoestiamteonetask = false
    }

    func abort() {
        selecteduuids.removeAll()
        inprogresscountmultipletask.resetcounts()
        _ = InterruptProcess()
        inwork = -1
        reload = true
        progressviewshowinfo = false
        showexecutenoestiamteonetask = false
    }

    func executeonenotestimatedtask() async {
        if selectedconfig != nil, selecteduuids.count == 0 {
            executeonetaskasync =
                ExecuteOnetaskAsync(configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                    updateinprogresscount: inprogresscountmultipletask,
                                    hiddenID: selectedconfig?.hiddenID)
            await executeonetaskasync?.execute()
        }
    }
}
