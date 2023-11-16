//
//  NavigationSidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

struct NavigationSidebarTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var reload: Bool
    @State private var estimatingprogressdetails = EstimateProgressDetails()
    @StateObject private var progressdetails = ExecuteProgressDetails()
    // Which view to show
    @State var path: [Tasks] = []

    var body: some View {
        NavigationStack(path: $path) {
            NavigationTasksView(estimatingprogressdetails: estimatingprogressdetails,
                                reload: $reload,
                                selecteduuids: $selecteduuids,
                                path: $path)
                .environmentObject(progressdetails)
                .navigationDestination(for: Tasks.self) { which in
                    makeView(view: which.task)
                }
                .task {
                    if SharedReference.shared.firsttime {
                        path.append(Tasks(task: .firsttime))
                    }
                }
        }
    }

    @ViewBuilder
    func makeView(view: DestinationView) -> some View {
        switch view {
        case .executestimatedview:
            // This view is activated for execution of estimated tasks and view
            // presents progress of synchronization of data.
            NavigationExecuteEstimatedTasksView(estimatingprogressdetails: estimatingprogressdetails,
                                                selecteduuids: $selecteduuids,
                                                reload: $reload,
                                                path: $path)
                .environmentObject(progressdetails)
        case .executenoestimatetasksview:
            // Execute tasks, no estimation ahead of synchronization
            NavigationExecuteNoestimatedTasksView(reload: $reload,
                                                  selecteduuids: $selecteduuids,
                                                  path: $path)
        case .estimatedview:
            NavigationSummarizedAllDetailsView(estimatingprogressdetails: estimatingprogressdetails,
                                               selecteduuids: $selecteduuids,
                                               path: $path)
                .environmentObject(progressdetails)
        case .firsttime:
            NavigationFirstTimeView()
        case .dryrunonetask:
            NavigationDetailsOneTaskRootView(selecteduuids: selecteduuids)
                .environment(estimatingprogressdetails)
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                }
        case .dryrunonetaskalreadyestimated:
            NavigationDetailsOneTask(selecteduuids: estimatingprogressdetails.uuids,
                                     estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [])
        case .alltasksview:
            NavigationAlltasksView()
        }
    }
}

enum DestinationView: String, Identifiable {
    case executestimatedview, executenoestimatetasksview,
         estimatedview, firsttime, dryrunonetask, alltasksview,
         dryrunonetaskalreadyestimated
    var id: String { rawValue }
}

struct Tasks: Hashable, Identifiable {
    let id = UUID()
    var task: DestinationView
}
