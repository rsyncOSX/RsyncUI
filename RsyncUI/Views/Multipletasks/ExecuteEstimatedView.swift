//
//  ExecuteEstimatedTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 07/02/2021.
//

import Foundation
import SwiftUI

struct ExecuteEstimatedView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails

    @StateObject private var multipletaskstate = MultipleTaskState()
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var selecteduuids: Set<UUID>
    @Binding var reload: Bool
    @Binding var showestimateview: Bool

    @State private var executemultipletasks: ExecuteMultipleTasks?
    @State private var selectedconfig: Configuration?
    @State private var presentsheetview = false
    @State private var inwork: Int = -1
    @State private var searchText: String = ""

    @State private var confirdelete = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig,
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               searchText: $searchText,
                               reload: $reload,
                               confirmdelete: $confirdelete)

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
    }

    // Present progressview during executing multiple tasks, progress about the number of
    // tasks are executed.
    var progressviewexecuting: some View {
        ProgressView()
            .frame(width: 25, height: 25)
            .onAppear(perform: {
                // To set ProgressView spinnig wheel on correct task when estimating
                inwork = inprogresscountmultipletask.hiddenID
                // executedetails.setcurrentprogress(0)
            })
            .onChange(of: inprogresscountmultipletask.getinprogress(), perform: { _ in
                // To set ProgressView spinnig wheel on correct task when estimating
                inwork = inprogresscountmultipletask.hiddenID
                executedetails.setcurrentprogress(0)
            })
    }

    // When status execution is .completed, presenet label and execute completed.
    // The label will probably not been seen by user, the status changes to .start in
    // completed job.
    var labelcompleted: some View {
        Label(multipletaskstate.executionstate.rawValue, systemImage: "play.fill")
            .onAppear(perform: {
                completed()
            })
    }

    var headingtitle: some View {
        Text("Execute tasks")
            .font(.title2)
            .padding()
    }
}

extension ExecuteEstimatedView {
    func completed() {
        inwork = -1
        multipletaskstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        executemultipletasks = nil
        selecteduuids.removeAll()
        showestimateview = true
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
        showestimateview = true
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
