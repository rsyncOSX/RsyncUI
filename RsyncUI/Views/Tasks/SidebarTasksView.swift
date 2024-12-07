//
//  SidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//
// swiftlint:disable cyclomatic_complexity

import OSLog
import SwiftUI

enum DestinationView: String, Identifiable {
    case executestimatedview, executenoestimatetasksview,
         summarizeddetailsview, onetaskdetailsview,
         dryrunonetaskalreadyestimated, quick_synchronize,
         completedview, viewlogfile
    var id: String { rawValue }
}

struct Tasks: Hashable, Identifiable {
    let id = UUID()
    var task: DestinationView
}

struct SidebarTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var executetasknavigation: [Tasks]

    @State private var executeprogressdetails = ExecuteProgressDetails()

    var body: some View {
        NavigationStack(path: $executetasknavigation) {
            TasksView(rsyncUIdata: rsyncUIdata,
                      executeprogressdetails: executeprogressdetails,
                      estimateprogressdetails: estimateprogressdetails,
                      selecteduuids: $selecteduuids,
                      path: $executetasknavigation)
                .navigationDestination(for: Tasks.self) { which in
                    makeView(view: which.task)
                }
        }
        .onChange(of: executetasknavigation) {
            Logger.process.info("Path : \(executetasknavigation, privacy: .public)")
        }
    }

    @MainActor @ViewBuilder
    func makeView(view: DestinationView) -> some View {
        switch view {
        case .executestimatedview:
            ExecuteEstimatedTasksView(rsyncUIdata: rsyncUIdata,
                                      executeprogressdetails: executeprogressdetails,
                                      selecteduuids: $selecteduuids,
                                      path: $executetasknavigation)
        case .executenoestimatetasksview:
            ExecuteNoestimatedTasksView(rsyncUIdata: rsyncUIdata,
                                        selecteduuids: $selecteduuids,
                                        path: $executetasknavigation)
        case .summarizeddetailsview:
            // After a complete estimation all tasks
            if let configurations = rsyncUIdata.configurations {
                SummarizedDetailsView(executeprogressdetails: executeprogressdetails,
                                      estimateprogressdetails: estimateprogressdetails,
                                      selecteduuids: $selecteduuids,
                                      path: $executetasknavigation,
                                      configurations: configurations,
                                      profile: rsyncUIdata.profile)
                    .onDisappear {
                        executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                    }
            }
        case .onetaskdetailsview:
            // After dry-run one task
            if let configurations = rsyncUIdata.configurations {
                OneTaskDetailsView(estimateprogressdetails: estimateprogressdetails,
                                   selecteduuids: selecteduuids,
                                   configurations: configurations)
                    .onDisappear {
                        executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                    }
            }
        case .dryrunonetaskalreadyestimated:
            if let estimates = estimateprogressdetails.estimatedlist?.filter({ $0.id == selecteduuids.first }) {
                if estimates.count == 1 {
                    DetailsView(remotedatanumbers: estimates[0])
                        .onDisappear(perform: {
                            selecteduuids.removeAll()
                        })
                }
            }
        case .quick_synchronize:
            QuicktaskView()
        case .completedview:
            CompletedView(path: $executetasknavigation)
                .onAppear {
                    reset()
                }
        case .viewlogfile:
            NavigationLogfileView()
        }
    }

    func reset() {
        executeprogressdetails.estimatedlist = nil
        estimateprogressdetails.resetcounts()
    }
}

// swiftlint:enable cyclomatic_complexity
