//
//  NavigationSidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import OSLog
import SwiftUI

@available(macOS 14.0, *)
struct NavigationSidebarTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var reload: Bool
    @State private var estimatingprogressdetails = EstimateProgressDetails14()
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
        .onChange(of: path) {
            Logger.process.info("Path : \(path)")
        }
    }

    @ViewBuilder
    func makeView(view: DestinationView) -> some View {
        switch view {
        case .executestimatedview:
            NavigationExecuteEstimatedTasksView(estimatingprogressdetails: estimatingprogressdetails,
                                                selecteduuids: $selecteduuids,
                                                reload: $reload,
                                                path: $path)
                .environmentObject(progressdetails)
        case .executenoestimatetasksview:
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
            NavigationDetailsOneTaskRootView(estimatingprogressdetails: estimatingprogressdetails,
                                             selecteduuids: selecteduuids)
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                }
        case .dryrunonetaskalreadyestimated:
            NavigationDetailsOneTask(estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [],
                                     selecteduuids: selecteduuids)
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
