//
//  NavigationSidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

@available(macOS 14.0, *)
struct NavigationSidebarTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var reload: Bool
    @StateObject private var estimatingprogressdetails = EstimateProgressDetails()
    @StateObject private var progressdetails = ExecuteProgressDetails()
    // Which view to show
    @State private var showview: DestinationView?
    @State private var showDetails: Bool = false

    var body: some View {
        NavigationStack {
            NavigationTasksView(reload: $reload,
                                selecteduuids: $selecteduuids,
                                showview: $showview)
                .environmentObject(progressdetails)
                .environmentObject(estimatingprogressdetails)

        }.navigationDestination(isPresented: $showDetails) {
            makeView(view: showview ?? .firsttime)
        }
        .onChange(of: showview) {
            guard showview != nil else { return }
            showDetails = true
        }
        .task {
            if SharedReference.shared.firsttime {
                showview = .firsttime
                showDetails = true
            }
        }
    }

    @ViewBuilder
    func makeView(view: DestinationView) -> some View {
        switch view {
        case .executestimatedview:
            // This view is activated for execution of estimated tasks and view
            // presents progress of synchronization of data.
            NavigationExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                                reload: $reload,
                                                showview: $showview)
                .environmentObject(progressdetails)
                .environmentObject(estimatingprogressdetails)
        case .executenoestimatetasksview:
            // Execute tasks, no estimation ahead of synchronization
            NavigationExecuteNoestimatedTasksView(reload: $reload,
                                                  selecteduuids: $selecteduuids,
                                                  showview: $showview)
        case .estimatedview:
            NavigationSummarizedAllDetailsView(selecteduuids: $selecteduuids,
                                               showview: $showview,
                                               estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [])
        case .firsttime:
            NavigationFirstTimeView()
        case .dryrunonetask:
            NavigationDetailsOneTaskRootView(selecteduuids: selecteduuids)
                .environmentObject(estimatingprogressdetails)
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                    showview = nil
                }
        case .dryrunonetaskalreadyestimated:
            NavigationDetailsOneTask(selecteduuids: selecteduuids,
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
