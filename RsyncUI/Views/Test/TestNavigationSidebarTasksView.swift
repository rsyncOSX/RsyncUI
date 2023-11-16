//
//  TestNavigationSidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/11/2023.
//

import SwiftUI

struct TestNavigationSidebarTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var reload: Bool
    @State private var estimatingprogressdetails = EstimateProgressDetails()
    @StateObject private var progressdetails = ExecuteProgressDetails()

    @State var path: [Tasks] = []
    @State var whichtask: TestDestinationView?

    var body: some View {
        NavigationStack(path: $path) {
            TestNavigationTasksView(estimatingprogressdetails: estimatingprogressdetails,
                                    reload: $reload,
                                    selecteduuids: $selecteduuids,
                                    path: $path)
                .environmentObject(progressdetails)
                .navigationDestination(for: Tasks.self) { which in
                    makeView(view: which.task)
                }
                .task {
                    if SharedReference.shared.firsttime {
                        // makeView(view: .firsttime)
                    }
                }
        }
        /*
         .onChange(of: whichtask) {
             var test = path.popLast()
             test?.task = whichtask ?? .alltasksview
             path.append(test ?? Tasks(task: .alltasksview))
         }
          */
    }

    @ViewBuilder
    func makeView(view: TestDestinationView?) -> some View {
        switch view {
        case .estimatedview:
            TestNavigationSummarizedAllDetailsView(selecteduuids: $selecteduuids,
                                                   path: $path,
                                                   estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [])
        case .firsttime:
            NavigationFirstTimeView()
        case .dryrunonetask:
            NavigationDetailsOneTaskRootView(selecteduuids: selecteduuids)
                .environment(estimatingprogressdetails)
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                }
        case .dryrunonetaskalreadyestimated:
            NavigationDetailsOneTask(selecteduuids: selecteduuids,
                                     estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [])
        case .alltasksview:
            NavigationAlltasksView()
        case .none:
            NavigationAlltasksView()
        }
    }
}

struct Tasks: Hashable, Identifiable {
    let id = UUID()
    var task: TestDestinationView
}

enum TestDestinationView: String, Identifiable {
    case estimatedview, firsttime, dryrunonetask, alltasksview,
         dryrunonetaskalreadyestimated
    var id: String { rawValue }
}
