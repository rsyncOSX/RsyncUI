//
//  ExecuteNoestimateOneTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/02/2023.
//

import SwiftUI

struct ExecuteNoestimateOneTaskView: View {
    @SwiftUI.Environment(RsyncUIconfigurations.self) private var rsyncUIdata
    @State private var estimatingprogresscount = EstimatingProgressCount()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showcompleted: Bool
    @Binding var showexecutenoestiamteonetask: Bool

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
                filterstring: $filterstring
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
        reload = true
        showcompleted = true
        estimatingprogresscount.resetcounts()
        progressviewshowinfo = false
        estimatingprogresscount.estimateasync = false
        showexecutenoestiamteonetask = false
    }

    func abort() {
        selecteduuids.removeAll()
        estimatingprogresscount.resetcounts()
        _ = InterruptProcess()
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
                                        updateinprogresscount: estimatingprogresscount,
                                        hiddenID: selectedconfig.config?.hiddenID)
                await executeonetaskasync?.execute()
            }
        } else {
            selectedconfig.config = nil
        }
    }
}
