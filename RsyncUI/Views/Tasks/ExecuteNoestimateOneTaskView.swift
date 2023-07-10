//
//  ExecuteNoestimateOneTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/02/2023.
//

import SwiftUI

struct ExecuteNoestimateOneTaskView: View {
    @SwiftUI.Environment(RsyncUIconfigurations.self) private var rsyncUIdata
    @State private var inprogresscountmultipletask = InprogressCountMultipleTasks()

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
    @State private var selectedconfig = Selectedconfig()

    @State private var reloadtasksviewlist: Bool = false
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
        let selected = rsyncUIdata.configurations?.filter { config in
            selecteduuids.contains(config.id)
        }
        if (selected?.count ?? 0) == 1 {
            if let config = selected {
                selectedconfig.config = config[0]
                executeonetaskasync =
                    ExecuteOnetaskAsync(configurations: rsyncUIdata,
                                        updateinprogresscount: inprogresscountmultipletask,
                                        hiddenID: selectedconfig.config?.hiddenID)
                await executeonetaskasync?.execute()
            }
        } else {
            selectedconfig.config = nil
        }
    }
}
