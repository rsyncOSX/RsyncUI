//
//  NavigationExecuteEstimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftUI

@available(macOS 14.0, *)
struct NavigationExecuteEstimatedTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var progressdetails: ExecuteProgressDetails
    @EnvironmentObject var estimatingprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<UUID>
    @Binding var reload: Bool
    @Binding var showview: DestinationView?
    @State private var multipletaskstate = MultipleTaskState()
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

@available(macOS 14.0, *)
extension NavigationExecuteEstimatedTasksView {
    func completed() {
        progressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        estimatingprogressdetails.resetcounts()
        selecteduuids.removeAll()
        reload = true
    }

    func abort() {
        progressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        estimatingprogressdetails.resetcounts()
        selecteduuids.removeAll()
        _ = InterruptProcess()
        reload = true
    }

    func executemultipleestimatedtasks() {
        var uuids: Set<Configuration.ID>?
        if selecteduuids.count > 0 {
            uuids = selecteduuids
        } else if estimatingprogressdetails.getuuids().count > 0 {
            uuids = estimatingprogressdetails.getuuids()
        }
        guard (uuids?.count ?? 0) > 0 else { return }
        if let uuids = uuids {
            multipletaskstate.updatestate(state: .execute)
            ExecuteMultipleTasks(uuids: uuids,
                                 profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata,
                                 multipletaskstateDelegate: multipletaskstate,
                                 estimateprogressdetailsDelegate: estimatingprogressdetails,
                                 executeprogressdetailsDelegate: progressdetails)
        }
    }
}
