//
//  SidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import OSLog
import SwiftUI

struct SidebarTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var reload: Bool
    @State private var estimateprogressdetails = EstimateProgressDetails()
    @StateObject private var executeprogressdetails = ExecuteProgressDetails()
    // Which view to show
    @State var path: [Tasks] = []

    var body: some View {
        NavigationStack(path: $path) {
            NavigationTasksView(estimateprogressdetails: estimateprogressdetails,
                                reload: $reload,
                                selecteduuids: $selecteduuids,
                                path: $path)
                .environmentObject(executeprogressdetails)
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
            NavigationExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                                reload: $reload,
                                                path: $path)
                .environmentObject(executeprogressdetails)
        case .executenoestimatetasksview:
            NavigationExecuteNoestimatedTasksView(reload: $reload,
                                                  selecteduuids: $selecteduuids,
                                                  path: $path)
        case .estimatedview:
            SummarizedAllDetailsView(estimateprogressdetails: estimateprogressdetails,
                                     selecteduuids: $selecteduuids,
                                     path: $path)
                .environmentObject(executeprogressdetails)
        case .firsttime:
            NavigationFirstTimeView()
        case .dryrunonetask:
            DetailsOneTaskRootView(estimateprogressdetails: estimateprogressdetails,
                                   selecteduuids: selecteduuids)
                .onDisappear {
                    executeprogressdetails.setestimatedlist(estimateprogressdetails.getestimatedlist())
                }
        case .dryrunonetaskalreadyestimated:
            DetailsOneTask(estimatedlist: estimateprogressdetails.getestimatedlist() ?? [],
                           selecteduuids: $selecteduuids)
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
