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
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var outputfromrsync: OutputFromRsync

    // Execute estimate and execution
    @StateObject private var singletaskstate = SingleTaskState()
    // Execute singletask, no estimation
    @StateObject private var singletasknowstate = SingletaskNowState()
    // Output from tasks are summarized and reported to the inprogresscountrsyncoutput object
    // Also progress about synchronizing, if estimated first
    @StateObject private var inprogresscountrsyncoutput = InprogressCountRsyncOutput()

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var singletaskview: Bool

    // Must be a @State because it is changed
    @State private var executesingletasks: ExecuteSingleTask?
    @State private var executetasknow: ExecuteSingleTaskNow?

    @State private var executestate: SingleTaskWork = .start
    @State private var presentsheetview = false
    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()

    // Not used but requiered in parameter
    @State private var inwork = -1
    // Selected row in output
    @State private var valueselectedrow: String = ""
    // If shellout
    @State private var shellout: Bool = false
    // Focus buttons from the menu
    // @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var searchText: String = ""

    @State private var numberoffiles: Int = 0

    var body: some View {
        ZStack {
            VStack {
                ConfigurationSelected(selectedconfig: $selectedconfig,
                                      selecteduuids: $selecteduuids,
                                      inwork: $inwork,
                                      reload: $reload)

                List(listitems, id: \.self) { line in
                    Text(line)
                        .modifier(FixedTag(750, .leading))
                }
            }
            .task {
                estimatesingletask()
            }

            // Estimate singletask or Execute task now
            if singletasknowstate.executetasknowstate == .execute {
                RotatingDotsIndicatorView()
                    .frame(width: 25.0, height: 25.0)
                    .foregroundColor(.red)
            }

            if singletaskstate.singletaskstate == .estimate {
                RotatingDotsIndicatorView()
                    .frame(width: 25.0, height: 25.0)
                    .foregroundColor(.red)
            }
        }
    }

    var listitems: [String] {
        return inprogresscountrsyncoutput.getoutput() ?? []
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
        singletaskstate.estimateonly = false
    }

    func estimatesingletask() {
        singletaskstate.estimateonly = true
        setuuidforsingletask()
        executeestimatedsingletask()
    }

    func presentoutput() {
        presentsheetview = true
    }

    func executeestimatedsingletask() {
        guard selecteduuids.count == 1 else { return }
        switch singletaskstate.singletaskstate {
        case .start:
            executesingletasks = nil
            executetasknow = nil
            singletaskstate.updatestate(state: .estimate)
            executesingletasks = ExecuteSingleTask(uuids: selecteduuids,
                                                   profile: rsyncUIdata.configurationsfromstore?.profile,
                                                   configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
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
        // kill any ongoing processes
        _ = InterruptProcess()
    }

    func executesingletasknow() {
        executesingletasks = nil
        executetasknow = nil
        setuuidforsingletask()
        guard selecteduuids.count == 1 else { return }
        singletasknowstate.updatestate(state: .execute)
        if let config = selectedconfig {
            if PreandPostTasks(config: config).executepretask || PreandPostTasks(config: config).executeposttask {
                executetasknow =
                    ExecuteSingleTaskNowShellout(uuids: selecteduuids,
                                                 profile: rsyncUIdata.configurationsfromstore?.profile,
                                                 configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                 executetaskstate: singletasknowstate,
                                                 updateinprogresscount: inprogresscountrsyncoutput)
            } else {
                executetasknow =
                    ExecuteSingleTaskNow(uuids: selecteduuids,
                                         profile: rsyncUIdata.configurationsfromstore?.profile,
                                         configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                         executetaskstate: singletasknowstate,
                                         updateinprogresscount: inprogresscountrsyncoutput)
            }
        }
    }

    func setuuidforsingletask() {
        selecteduuids.removeAll()
        if let sel = selectedconfig,
           let index = rsyncUIdata.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncUIdata.configurations?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
