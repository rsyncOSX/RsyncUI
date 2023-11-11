//
//  NavigationExecuteEstimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftUI

struct NavigationExecuteEstimatedTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @EnvironmentObject var progressdetails: ExecuteProgressDetails
    @State private var estimatingprogresscount = EstimateProgressDetails()
    @State private var multipletaskstate = MultipleTaskState()
    @Binding var selecteduuids: Set<UUID>
    @Binding var reload: Bool
    @Binding var showview: DestinationView
    @State private var selectedconfig: Configuration?
    @State private var filterstring: String = ""
    @State private var focusaborttask: Bool = false
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            ListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                doubleclick: $doubleclick,
                showestimateicon: false
            )

            if multipletaskstate.executionstate == .completed { labelcompleted }
            if multipletaskstate.executionstate == .execute { AlertToast(displayMode: .alert, type: .loading) }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
        .onDisappear(perform: {
            progressdetails.resetcounter()
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

extension NavigationExecuteEstimatedTasksView {
    func completed() {
        progressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        estimatingprogresscount.resetcounts()
        selecteduuids.removeAll()
        showview = .taskview
        reload = true
    }

    func abort() {
        progressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        estimatingprogresscount.resetcounts()
        selecteduuids.removeAll()
        _ = InterruptProcess()
        showview = .taskview
        reload = true
    }

    func executemultipleestimatedtasks() {
        guard selecteduuids.count > 0 else {
            showview = .taskview
            return
        }
        multipletaskstate.updatestate(state: .execute)
        ExecuteMultipleTasks(uuids: selecteduuids,
                             profile: rsyncUIdata.profile,
                             configurations: rsyncUIdata,
                             multipletaskstateDelegate: multipletaskstate,
                             estimateprogressdetailsDelegate: estimatingprogresscount,
                             executeprogressdetailsDelegate: progressdetails)
    }
}
