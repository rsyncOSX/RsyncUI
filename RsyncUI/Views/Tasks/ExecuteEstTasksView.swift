//
//  ExecuteEstTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

struct ExecuteEstTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<UUID>
    // Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]

    @State private var focusaborttask: Bool = false
    @State private var doubleclick: Bool = false
    // Progress of synchronization
    @State private var progress: Double = 0
    @State private var maxcount: Double = 0

    var body: some View {
        VStack(alignment: .leading) {
            ListofTasksMainView(
                rsyncUIdata: rsyncUIdata,
                selecteduuids: $selecteduuids,
                doubleclick: $doubleclick,
                progress: $progress,
                progressdetails: progressdetails,
                max: maxcount
            )
            .onChange(of: progressdetails.hiddenIDatwork) {
                maxcount = progressdetails.getmaxcountbytask()
            }

            // if executestate.executestate == .execute { ProgressView() }
            if focusaborttask { labelaborttask }
        }
        .onAppear {
            executemultipleestimatedtasks()
        }
        .onDisappear {
            progressdetails.estimatedlist = nil
            rsyncUIdata.executetasksinprogress = false
            if SharedReference.shared.process != nil {
                InterruptProcess()
            }
        }
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

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }
}

extension ExecuteEstTasksView {
    func filehandler(count: Int) {
        progress = Double(count)
    }

    func abort() {
        progressdetails.hiddenIDatwork = -1
        selecteduuids.removeAll()
        InterruptProcess()
        executetaskpath.removeAll()
    }

    func executemultipleestimatedtasks() {
        var adjustedselecteduuids: Set<SynchronizeConfiguration.ID>?
        if selecteduuids.count > 0 {
            adjustedselecteduuids = selecteduuids
        } else {
            if let estimatedlist = progressdetails.estimatedlist {
                adjustedselecteduuids = Set<SynchronizeConfiguration.ID>()
                _ = estimatedlist.map { estimate in
                    if estimate.datatosynchronize == true {
                        adjustedselecteduuids?.insert(estimate.id)
                    }
                }
            }
        }
        guard (adjustedselecteduuids?.count ?? 0) > 0 else {
            progressdetails.estimatedlist = nil
            rsyncUIdata.executetasksinprogress = false
            executetaskpath.removeAll()
            return
        }
        if let adjustedselecteduuids {
            Logger.process.info("ExecuteEstimatedTasksView: executemultipleestimatedtasks(): \(adjustedselecteduuids, privacy: .public)")
            if let configurations = rsyncUIdata.configurations {
                EstimateExecute(profile: rsyncUIdata.profile,
                                configurations: configurations,
                                selecteduuids: adjustedselecteduuids,
                                progressdetails: progressdetails,
                                filehandler: filehandler,
                                updateconfigurations: updateconfigurations,
                                excutetasks: true)
            }
        }
    }

    func updateconfigurations(_ configurations: [SynchronizeConfiguration]) {
        Logger.process.info("ExecuteEstimatedTasksView: updateconfigurations() in memory\nReset data and return to MAIN THREAD task view")
        rsyncUIdata.configurations = configurations
        progressdetails.hiddenIDatwork = -1
        progressdetails.estimatedlist = nil
        rsyncUIdata.executetasksinprogress = false
        selecteduuids.removeAll()
        executetaskpath.append(Tasks(task: .completedview))
    }
}
