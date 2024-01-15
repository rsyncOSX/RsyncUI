//
//  SidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import OSLog
import SwiftUI

struct SidebarTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>

    @State private var executeprogressdetails = ExecuteProgressDetails()
    @State private var estimateprogressdetails = EstimateProgressDetails()
    // Which view to show
    @State var path: [Tasks] = []

    var body: some View {
        NavigationStack(path: $path) {
            TasksView(rsyncUIdata: rsyncUIdata,
                      executeprogressdetails: executeprogressdetails,
                      estimateprogressdetails: estimateprogressdetails,

                      selecteduuids: $selecteduuids,
                      path: $path)
                .navigationDestination(for: Tasks.self) { which in
                    makeView(view: which.task)
                }
                .task {
                    if SharedReference.shared.firsttime {
                        path.append(Tasks(task: .firsttime))
                    }
                }
        }
        .onChange(of: path) {
            Logger.process.info("Path : \(path, privacy: .public)")
        }
    }

    @ViewBuilder
    func makeView(view: DestinationView) -> some View {
        switch view {
        case .executestimatedview:
            ExecuteEstimatedTasksView(rsyncUIdata: rsyncUIdata,
                                      executeprogressdetails: executeprogressdetails,
                                      selecteduuids: $selecteduuids,

                                      path: $path)
        case .executenoestimatetasksview:
            ExecuteNoestimatedTasksView(rsyncUIdata: rsyncUIdata,

                                        selecteduuids: $selecteduuids,
                                        path: $path)
        case .estimatedview:
            SummarizedAllDetailsView(rsyncUIdata: rsyncUIdata,
                                     executeprogressdetails: executeprogressdetails,
                                     estimateprogressdetails: estimateprogressdetails,
                                     selecteduuids: $selecteduuids,
                                     path: $path)
        case .firsttime:
            FirstTimeView()
        case .dryrunonetask:
            DetailsOneTaskEstimatingView(rsyncUIdata: rsyncUIdata,
                                         estimateprogressdetails: estimateprogressdetails,
                                         selecteduuids: selecteduuids)
                .onDisappear {
                    executeprogressdetails.estimatedlist = estimateprogressdetails.getestimatedlist()
                }
        case .dryrunonetaskalreadyestimated:
            if let estimates = estimateprogressdetails.getestimatedlist()?.filter({ $0.id == selecteduuids.first }) {
                if estimates.count == 1 {
                    DetailsOneTask(estimatedtask: estimates[0])
                        .onDisappear(perform: {
                            selecteduuids.removeAll()
                        })
                }
            }
        case .alltasksview:
            AlltasksView()
        case .viewlogfile:
            NavigationLogfileView()
        }
    }
}

enum DestinationView: String, Identifiable {
    case executestimatedview, executenoestimatetasksview,
         estimatedview, firsttime, dryrunonetask, alltasksview,
         dryrunonetaskalreadyestimated, viewlogfile
    var id: String { rawValue }
}

struct Tasks: Hashable, Identifiable {
    let id = UUID()
    var task: DestinationView
}
