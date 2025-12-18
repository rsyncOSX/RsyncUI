//
//  SidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//
// swiftlint:disable identifier_name

import OSLog
import SwiftUI

enum DestinationView: String, Identifiable {
    case executestimatedview, executenoestimatetasksview,
         summarizeddetailsview, onetaskdetailsview,
         dryrunonetaskalreadyestimated, quick_synchronize,
         completedview, charts
    var id: String { rawValue }
}

struct Tasks: Hashable, Identifiable {
    let id = UUID()
    var task: DestinationView
}

struct SidebarTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var progressdetails: ProgressDetails
    @Bindable var schedules: ObservableSchedules

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
                      schedules: schedules,
                      selecteduuids: $selecteduuids,
                      executetaskpath: $executetaskpath,
                      urlcommandestimateandsynchronize: $urlcommandestimateandsynchronize,
                      columnVisibility: $columnVisibility,
                      selectedprofileID: $selectedprofileID)
                .navigationDestination(for: Tasks.self) { which in
                    makeView(view: which.task)
                }
        }
        .onChange(of: queryitem) {
            // URL code
            handleQueryItem()
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
            summarizedDetailsViewContent()
        case .onetaskdetailsview:
            oneTaskDetailsViewContent()
        case .dryrunonetaskalreadyestimated:
            dryRunDetailsViewContent()
        case .quick_synchronize:
            QuicktaskView(
                homecatalogs: HomeCatalogsService().homeCatalogs()
            )
        case .completedview:
            CompletedView(executetaskpath: $executetaskpath)
                .onAppear {
                    reset()
                }
        case .charts:
            LogStatsChartView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
        }
    }

    @MainActor @ViewBuilder
    private func summarizedDetailsViewContent() -> some View {
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
    }

    @MainActor @ViewBuilder
    private func oneTaskDetailsViewContent() -> some View {
        // After dry-run one task
        if let configurations = rsyncUIdata.configurations {
            OneTaskDetailsView(progressdetails: progressdetails,
                               selecteduuids: selecteduuids,
                               configurations: configurations)
        }
    }

    @MainActor @ViewBuilder
    private func dryRunDetailsViewContent() -> some View {
        if let estimates = progressdetails.estimatedlist?.filter({ $0.id == selecteduuids.first }) {
            if estimates.count == 1 {
                DetailsView(remotedatanumbers: estimates[0])
                    .onDisappear {
                        selecteduuids.removeAll()
                    }
            }
        }
    }

    func reset() {
        progressdetails.resetCounts()
        rsyncUIdata.executetasksinprogress = false
        queryitem = nil
    }
}

extension SidebarTasksView {
    // URL code
    private func handleQueryItem() {
        Logger.process.debugMessageOnly("SidebarTasksView: Change on queryitem discovered")
        if queryitem != nil {
            if let name = queryitem?.name {
                if name == "id" {
                    // The Verify is no longer supported
                    queryitem = nil
                } else if name == "profile" {
                    executetaskpath.append(Tasks(task: .summarizeddetailsview))
                }
            }
        }
    }
}
// swiftlint:enable identifier_name
