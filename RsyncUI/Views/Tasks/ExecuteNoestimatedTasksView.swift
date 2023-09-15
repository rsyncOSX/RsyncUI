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
    @StateObject private var estimatingprogresscount = EstimateProgressDetails()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    // @Binding var showcompleted: Bool
    @Binding var showexecutenoestimateview: Bool

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
        /*
         HStack {
             Spacer()

             Button("Abort") { abort() }
                 .buttonStyle(ColorfulRedButtonStyle())
         }
          */
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
                .tooltip("Abort (⌘K)")
            }

            ToolbarItem {
                Spacer()
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
        // showcompleted = true
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
            ExecuteTasksAsync(profile: rsyncUIdata.profile,
                              configurations: rsyncUIdata,
                              updateinprogresscount: estimatingprogresscount,
                              uuids: selecteduuids,
                              filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}
