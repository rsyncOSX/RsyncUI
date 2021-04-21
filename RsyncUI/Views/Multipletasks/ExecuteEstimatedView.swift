//
//  ExecuteEstimatedTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 07/02/2021.
//

import Foundation
import SwiftUI

struct ExecuteEstimatedView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails

    @StateObject private var multipletaskstate = MultipleTaskState()
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var selecteduuids: Set<UUID>
    @Binding var reload: Bool
    @Binding var showestimateview: Bool
    // Either selectable configlist or not
    @State private var selectable = true

    @State private var executemultipletasks: ExecuteMultipleTasks?
    @State private var selectedconfig: Configuration?
    @State private var presentsheetview = false
    @State private var executedlist: [RemoteinfonumbersOnetask]?
    @State private var inexectuion: Int = -1

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig,
                           selecteduuids: $selecteduuids,
                           inwork: $inexectuion,
                           selectable: $selectable)

        // Execute multiple tasks progress
        if multipletaskstate.executionstate == .execute { progressviewexecuting }
        // When completed
        if multipletaskstate.executionstate == .completed { labelcompleted }

        HStack {
            Spacer()

            Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
    }

    // Present progressview during executing multiple tasks, progress about the number of
    // tasks are executed.
    var progressviewexecuting: some View {
        ProgressView(NSLocalizedString("Executing tasks", comment: "Execute Multiple tasks") + "…",
                     value: inprogresscountmultipletask.getinprogress(),
                     total: Double(inprogresscountmultipletask.getmaxcount()))
            .onAppear(perform: {
                // To set ProgressView spinnig wheel on correct task when estimating
                inexectuion = inprogresscountmultipletask.hiddenID
                // executedetails.setcurrentprogress(0)
            })
            .onChange(of: inprogresscountmultipletask.getinprogress(), perform: { _ in
                // To set ProgressView spinnig wheel on correct task when estimating
                inexectuion = inprogresscountmultipletask.hiddenID
                executedetails.setcurrentprogress(0)
            })
            .progressViewStyle(DarkBlueShadowProgressViewStyle())
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
        Text(NSLocalizedString("Execute tasks", comment: "RsyncCommandView"))
            .font(.title2)
            .padding()
    }
}

extension ExecuteEstimatedView {
    func dismissview() {
        inexectuion = -1
        multipletaskstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        executemultipletasks = nil
        selecteduuids.removeAll()
        showestimateview = true
    }

    func completed() {
        inexectuion = -1
        multipletaskstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        executemultipletasks = nil
        selecteduuids.removeAll()
        showestimateview = true
        reload = true
    }

    func abort() {
        inexectuion = -1
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
                                 profile: rsyncUIData.rsyncdata?.profile,
                                 configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
                                 schedulesSwiftUI: rsyncUIData.rsyncdata?.scheduleData,
                                 executionstateDelegate: multipletaskstate,
                                 updateinprogresscount: inprogresscountmultipletask,
                                 singletaskupdate: executedetails)
    }
}
