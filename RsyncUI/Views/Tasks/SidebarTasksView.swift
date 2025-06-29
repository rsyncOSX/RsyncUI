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
    @Bindable var progressdetails: ProgressDetails

    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    // Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]
    // URL code
    @Binding var queryitem: URLQueryItem?
    @Binding var urlcommandestimateandsynchronize: Bool
    // Show or hide Toolbox
    @Binding var columnVisibility: NavigationSplitViewVisibility
    // Selected profile
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?

    var body: some View {
        NavigationStack(path: $executetaskpath) {
            TasksView(rsyncUIdata: rsyncUIdata,
                      progressdetails: progressdetails,
                      selecteduuids: $selecteduuids,
                      executetaskpath: $executetaskpath,
                      urlcommandestimateandsynchronize: $urlcommandestimateandsynchronize,
                      columnVisibility: $columnVisibility,
                      selectedprofileID: $selectedprofileID)
                .navigationDestination(for: Tasks.self) { which in
                    makeView(view: which.task)
                }
        }
        .onChange(of: executetaskpath) {
            Logger.process.info("SidebarTasksView: executetaskpath \(executetaskpath, privacy: .public)")
        }
        .onChange(of: queryitem) {
            // URL code
            handlequeryitem()
        }
    }

    @MainActor @ViewBuilder
    func makeView(view: DestinationView) -> some View {
        switch view {
        case .executestimatedview:
            ExecuteEstTasksView(rsyncUIdata: rsyncUIdata,
                                progressdetails: progressdetails,
                                selecteduuids: $selecteduuids,
                                executetaskpath: $executetaskpath)
        case .executenoestimatetasksview:
            ExecuteNoEstTasksView(rsyncUIdata: rsyncUIdata,
                                  selecteduuids: $selecteduuids,
                                  executetaskpath: $executetaskpath)
        case .summarizeddetailsview:
            // After a complete estimation all tasks
            if let configurations = rsyncUIdata.configurations {
                SummarizedDetailsView(progressdetails: progressdetails,
                                      selecteduuids: $selecteduuids,
                                      executetaskpath: $executetaskpath,
                                      configurations: configurations,
                                      profile: rsyncUIdata.profile,
                                      queryitem: queryitem)
                    .onDisappear {
                        queryitem = nil
                    }
            }
        case .onetaskdetailsview:
            // After dry-run one task
            if let configurations = rsyncUIdata.configurations {
                OneTaskDetailsView(progressdetails: progressdetails,
                                   selecteduuids: selecteduuids,
                                   configurations: configurations)
            }
        case .dryrunonetaskalreadyestimated:
            if let estimates = progressdetails.estimatedlist?.filter({ $0.id == selecteduuids.first }) {
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
            CompletedView(executetaskpath: $executetaskpath)
                .onAppear {
                    reset()
                }
        case .viewlogfile:
            NavigationLogfileView()
        }
    }

    func reset() {
        progressdetails.resetcounts()
        rsyncUIdata.executetasksinprogress = false
        queryitem = nil
    }
}

extension SidebarTasksView {
    // URL code
    private func handlequeryitem() {
        Logger.process.info("SidebarTasksView: Change on queryitem discovered")
        if queryitem != nil {
            executetaskpath.append(Tasks(task: .summarizeddetailsview))
        }
    }
}

// swiftlint:enable cyclomatic_complexity
