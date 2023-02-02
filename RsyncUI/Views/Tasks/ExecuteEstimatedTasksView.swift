//
//  ExecuteEstimatedTasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 07/02/2021.
//

import SwiftUI

struct ExecuteEstimatedTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails

    @StateObject private var multipletaskstate = MultipleTaskState()
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var selecteduuids: Set<UUID>
    @Binding var reload: Bool
    @Binding var showeexecutestimatedview: Bool

    @State private var executemultipletasks: ExecuteMultipleTasks?
    @State private var selectedconfig: Configuration?
    @State private var inwork: Int = -1
    @State private var searchText: String = ""

    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig,
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               searchText: $searchText,
                               reload: $reload,
                               confirmdelete: $confirmdelete)

            // When completed
            if multipletaskstate.executionstate == .completed { labelcompleted }
        }
        HStack {
            Spacer()

            // Execute multiple tasks progress
            if multipletaskstate.executionstate == .execute { progressviewexecuting }

            Spacer()

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
        .focusedSceneValue(\.aborttask, $focusaborttask)
    }

    // Present progressview during executing multiple tasks
    var progressviewexecuting: some View {
        ProgressView()
            .frame(width: 25, height: 25)
            .onAppear(perform: {
                // To set ProgressView spinnig wheel on correct task when estimating
                inwork = inprogresscountmultipletask.hiddenID
            })
            .onChange(of: inprogresscountmultipletask.getinprogress(), perform: { _ in
                // To set ProgressView spinnig wheel on correct task when estimating
                inwork = inprogresscountmultipletask.hiddenID
                executedetails.setcurrentprogress(0)
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

extension ExecuteEstimatedTasksView {
    func completed() {
        inwork = -1
        multipletaskstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        executemultipletasks = nil
        selecteduuids.removeAll()
        showeexecutestimatedview = false
        reload = true
    }

    func abort() {
        inwork = -1
        multipletaskstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        executemultipletasks?.abort()
        executemultipletasks = nil
        selecteduuids.removeAll()
        _ = InterruptProcess()
        showeexecutestimatedview = false
        reload = true
    }

    func executemultipleestimatedtasks() {
        guard selecteduuids.count > 0 else { return }
        multipletaskstate.updatestate(state: .execute)
        executemultipletasks =
            ExecuteMultipleTasks(uuids: selecteduuids,
                                 profile: rsyncUIdata.configurationsfromstore?.profile,
                                 configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                 executionstateDelegate: multipletaskstate,
                                 updateinprogresscount: inprogresscountmultipletask,
                                 singletaskupdate: executedetails)
    }
}
