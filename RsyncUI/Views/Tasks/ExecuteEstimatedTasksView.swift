//
//  ExecuteEstimatedTasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 07/02/2021.
//

import SwiftUI

struct ExecuteEstimatedTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var progressdetails: ProgressDetails

    @StateObject private var multipletaskstate = MultipleTaskState()
    @StateObject private var estimatingprogresscount = EstimatingProgressCount()

    @Binding var selecteduuids: Set<UUID>
    @Binding var reload: Bool
    @Binding var showeexecutestimatedview: Bool

    @State private var selectedconfig: Configuration?
    @State private var filterstring: String = ""

    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    @State private var reloadtasksviewlist = false
    // Double click, only for macOS13 and later
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            ListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                confirmdelete: $confirmdelete,
                reloadtasksviewlist: $reloadtasksviewlist,
                doubleclick: $doubleclick
            )

            if multipletaskstate.executionstate == .completed { labelcompleted }
            if multipletaskstate.executionstate == .execute { AlertToast(displayMode: .alert, type: .loading) }
        }
        HStack {
            Spacer()

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
        .onDisappear(perform: {
            progressdetails.resetcounter()
        })
        .focusedSceneValue(\.aborttask, $focusaborttask)
    }

    // When status execution is .completed, present label and execute completed.
    var labelcompleted: some View {
        Label(multipletaskstate.executionstate.rawValue, systemImage: "play.fill")
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

extension ExecuteEstimatedTasksView {
    func completed() {
        progressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        estimatingprogresscount.resetcounts()
        selecteduuids.removeAll()
        showeexecutestimatedview = false
        reload = true
    }

    func abort() {
        progressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        estimatingprogresscount.resetcounts()
        selecteduuids.removeAll()
        _ = InterruptProcess()
        showeexecutestimatedview = false
        reload = true
    }

    func executemultipleestimatedtasks() {
        guard selecteduuids.count > 0 else {
            showeexecutestimatedview = false
            return
        }
        multipletaskstate.updatestate(state: .execute)
        ExecuteMultipleTasks(uuids: selecteduuids,
                             profile: rsyncUIdata.profile,
                             configurations: rsyncUIdata,
                             executionstateDelegate: multipletaskstate,
                             updateinprogresscount: estimatingprogresscount,
                             progressdetails: progressdetails)
    }
}
