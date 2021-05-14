//
//  SingleTasksView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 09/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import SwiftUI

struct SingleTasksView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @EnvironmentObject var outputfromrsync: OutputFromRsync
    // Observing shortcuts
    @EnvironmentObject var shortcuts: ShortcutActions

    // Execute estimate and execution
    @StateObject private var singletaskstate = SingleTaskState()
    // Execute singletask, no estimation
    @StateObject private var singletasknowstate = SingletaskNowState()
    // Output from tasks are summarized and reported to the inprogresscountrsyncoutput object
    // Also progress about synchronizing, if estimated first
    @StateObject private var inprogresscountrsyncoutput = InprogressCountRsyncOutput()

    @State private var executesingletasks: ExecuteSingleTask?
    @State private var executetasknow: ExecuteSingleTaskNow?
    @State private var selectedconfig: Configuration?
    @State private var executestate: SingleTaskWork = .start
    @State private var presentsheetview = false
    @State private var output: [String]?
    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()
    @Binding var reload: Bool

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    // Selected row in output
    @State private var valueselectedrow: String = ""
    // If shellout
    @State private var shellout: Bool = false
    // Alert for select tasks
    @State private var notasks: Bool = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { resetexecutestate() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)

            // Estimate singletask or Execute task now
            if singletasknowstate.executetasknowstate == .execute {
                RotatingDotsIndicatorView()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
            }

            if singletaskstate.singletaskstate == .estimate {
                RotatingDotsIndicatorView()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
            }

            if notasks == true {
                AlertToast(type: .regular, title: Optional(NSLocalizedString("Select a task",
                                                                             comment: "settings")), subTitle: Optional(""))
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            notasks = false
                        }
                    })
            }
        }

        if shellout { notifyshellout }

        HStack {
            if singletaskstate.singletaskstate != .start { labelestimate }
            if singletasknowstate.executetasknowstate != .start { labelexecutenow }
            // Shortcuts
            if shortcuts.estimatesingletask { labelshortcutestimation }
            if shortcuts.executesingletask { labelshortcutexecute }

            Spacer()
        }

        HStack {
            HStack {
                estimateandexecute

                executenow
            }

            Spacer()

            // Execute singletask
            if singletaskstate.singletaskstate == .estimated { progressviewexecute }

            Spacer()

            Button(NSLocalizedString("View", comment: "View button")) { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .onAppear(perform: {
            shortcuts.enablesingletask()
        })
        .onDisappear(perform: {
            shortcuts.disablesingletask()
        })
    }

    // Estimate and the execute.
    var estimateandexecute: some View {
        HStack {
            if singletaskstate.singletaskstate == .start ||
                singletaskstate.singletaskstate == .estimate {
                // Estimate
                Button(NSLocalizedString("Estimate", comment: "Estimate button")) { initsingletask() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                // Execute estimated
                Button(NSLocalizedString("Execute", comment: "Execute button")) { singletask() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            }
        }
    }

    // No estiamtion, just execute task now
    var executenow: some View {
        return Button(NSLocalizedString("Now", comment: "Now button")) { singletasknow() }
            .buttonStyle(PrimaryButtonStyle())
    }

    var progressviewexecute: some View {
        ProgressView(NSLocalizedString("", comment: "Execute tasks") + "…",
                     value: inprogresscountrsyncoutput.getinprogress(),
                     total: Double(inprogresscountrsyncoutput.getmaxcount()))
            .onChange(of: inprogresscountrsyncoutput.getinprogress(), perform: { _ in
            })
            .progressViewStyle(GaugeProgressStyle())
            .frame(width: 50.0, height: 50.0)
            .contentShape(Rectangle())
    }

    var labelshortcutestimation: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                shortcuts.estimatesingletask = false
                // Guard statement must be after resetting properties to false
                initsingletask()
            })
    }

    var labelshortcutexecute: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                shortcuts.executesingletask = false
                // Guard statement must be after resetting properties to false
                singletask()
            })
    }

    // When status == .completed execute completed for reload
    var labelestimate: some View {
        Label("", systemImage: "play.fill")
            .onChange(of: singletaskstate.singletaskstate, perform: { _ in
                if singletaskstate.singletaskstate == .completed { completed() }
            })
    }

    // When status == .completed execute completed for reload
    var labelexecutenow: some View {
        Label("", systemImage: "play.fill")
            .onChange(of: singletasknowstate.executetasknowstate, perform: { _ in
                if singletasknowstate.executetasknowstate == .completed { completed() }
            })
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        output: $output,
                        valueselectedrow: $valueselectedrow)
    }

    var notifyshellout: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Pre and post task", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }
}

extension SingleTasksView {
    func completed() {
        if let output = inprogresscountrsyncoutput.getoutput() {
            outputfromrsync.setoutput(output: output)
        }
        reload = true
        selecteduuids.removeAll()
        singletaskstate.updatestate(state: .start)
        singletasknowstate.updatestate(state: .start)
        inprogresscountrsyncoutput.resetcounts()
        executesingletasks = nil
        executetasknow = nil
    }

    func initsingletask() {
        setuuidforsingletask()
        singletask()
    }

    func presentoutput() {
        // Output from realrun
        output = outputfromrsync.getoutput()
        // Output from estimation run
        if output == nil {
            output = inprogresscountrsyncoutput.getoutput()
        }
        presentsheetview = true
    }

    func singletask() {
        guard selecteduuids.count == 1 else {
            notasks = true
            return
        }
        switch singletaskstate.singletaskstate {
        case .start:
            executesingletasks = nil
            executetasknow = nil
            singletaskstate.updatestate(state: .estimate)
            executesingletasks = ExecuteSingleTask(uuids: selecteduuids,
                                                   profile: rsyncUIData.rsyncdata?.profile,
                                                   configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
                                                   schedulesSwiftUI: rsyncUIData.rsyncdata?.scheduleData,
                                                   singletaskstate: singletaskstate,
                                                   updateinprogresscount: inprogresscountrsyncoutput)
            executesingletasks?.estimate()
        case .execute:
            singletaskstate.updatestate(state: .estimated)
            executesingletasks?.execute()
        default:
            return
        }
    }

    func abort() {
        singletaskstate.updatestate(state: .start)
        singletasknowstate.updatestate(state: .start)
        executesingletasks?.abort()
        executetasknow?.abort()
        executesingletasks = nil
        executetasknow = nil
        inprogresscountrsyncoutput.resetcounts()
        // kill any ongoing processes
        _ = InterruptProcess()
        reload = true
    }

    func resetexecutestate() {
        singletaskstate.updatestate(state: .start)
        singletasknowstate.updatestate(state: .start)
        executesingletasks = nil
        executetasknow = nil
        inprogresscountrsyncoutput.resetcounts()
        if let config = selectedconfig {
            if (config.executepretask ?? -1) == 1 {
                shellout = true
            } else {
                shellout = false
            }
        }
        // kill any ongoing processes
        _ = InterruptProcess()
    }

    func singletasknow() {
        executesingletasks = nil
        executetasknow = nil
        setuuidforsingletask()
        guard selecteduuids.count == 1 else {
            notasks = true
            return
        }
        singletasknowstate.updatestate(state: .execute)
        if let config = selectedconfig {
            if PreandPostTasks(config: config).executepretask || PreandPostTasks(config: config).executeposttask {
                executetasknow =
                    ExecuteSingleTaskNowShellout(uuids: selecteduuids,
                                                 profile: rsyncUIData.rsyncdata?.profile,
                                                 configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
                                                 schedulesSwiftUI: rsyncUIData.rsyncdata?.scheduleData,
                                                 executetaskstate: singletasknowstate,
                                                 updateinprogresscount: inprogresscountrsyncoutput)
            } else {
                executetasknow =
                    ExecuteSingleTaskNow(uuids: selecteduuids,
                                         profile: rsyncUIData.rsyncdata?.profile,
                                         configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
                                         schedulesSwiftUI: rsyncUIData.rsyncdata?.scheduleData,
                                         executetaskstate: singletasknowstate,
                                         updateinprogresscount: inprogresscountrsyncoutput)
            }
        }
    }

    func setuuidforsingletask() {
        selecteduuids.removeAll()
        if let sel = selectedconfig,
           let index = rsyncUIData.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncUIData.configurations?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
