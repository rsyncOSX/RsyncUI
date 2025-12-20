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
    @State private var progresscount: Double = 0
    @State private var maxcount: Double = 0

    var body: some View {
        VStack(alignment: .leading) {
            
            ZStack {
                ListofTasksMainView(
                    rsyncUIdata: rsyncUIdata,
                    selecteduuids: $selecteduuids,
                    doubleclick: $doubleclick,
                    progress: $progresscount,
                    progressdetails: progressdetails,
                    max: maxcount
                )
                .onChange(of: progressdetails.hiddenIDatwork) {
                    maxcount = progressdetails.getMaxCountByTask()
                }
                
                Text("Synchronizing tasks, please wait...")
                    .font(.title2)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
            }
            
            if focusaborttask { labelaborttask }
        }
        .onAppear {
            executeMultipleEstimatedTasks()
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
    func fileHandler(count: Int) {
        progresscount = Double(count)
    }

    func abort() {
        progressdetails.hiddenIDatwork = -1
        selecteduuids.removeAll()
        InterruptProcess()
        executetaskpath.removeAll()
    }

    func executeMultipleEstimatedTasks() {
        var adjustedselecteduuids: Set<SynchronizeConfiguration.ID>?
        if selecteduuids.count > 0 {
            adjustedselecteduuids = selecteduuids
        } else {
            if let estimatedlist = progressdetails.estimatedlist {
                adjustedselecteduuids = Set<SynchronizeConfiguration.ID>()
                for estimate in estimatedlist where estimate.datatosynchronize {
                    adjustedselecteduuids?.insert(estimate.id)
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
            if let configurations = rsyncUIdata.configurations {
                Execute(profile: rsyncUIdata.profile,
                        configurations: configurations,
                        selecteduuids: adjustedselecteduuids,
                        progressdetails: progressdetails,
                        fileHandler: fileHandler,
                        updateconfigurations: updateConfigurations)
            }
        }
    }

    func updateConfigurations(_ configurations: [SynchronizeConfiguration]) {
        rsyncUIdata.configurations = configurations
        progressdetails.hiddenIDatwork = -1
        progressdetails.estimatedlist = nil
        rsyncUIdata.executetasksinprogress = false
        selecteduuids.removeAll()
        executetaskpath.append(Tasks(task: .completedview))
    }
}
