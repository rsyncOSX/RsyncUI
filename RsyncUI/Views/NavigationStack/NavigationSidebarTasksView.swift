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
    @State private var showview: DestinationView?
    @State private var showDetails: Bool = false

    var body: some View {
        NavigationStack {
            NavigationTasksView(reload: $reload,
                                selecteduuids: $selecteduuids,
                                showview: $showview,
                                estimatingprogressdetails: estimatingprogressdetails)
                .environmentObject(progressdetails)
        }.navigationDestination(isPresented: $showDetails) {
            makeView(view: showview ?? .taskview)
        }
        .onChange(of: showview) {
            if showview == .taskview {
                showDetails = false
            } else {
                showDetails = true
            }
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
        case .taskview:
            // This is default main view
            // Never presented
            NavigationTasksView(reload: $reload,
                                selecteduuids: $selecteduuids,
                                showview: $showview,
                                estimatingprogressdetails: estimatingprogressdetails)
                .environmentObject(progressdetails)
        case .executestimatedview:
            // This view is activated for execution of estimated tasks and view
            // presents progress of synchronization of data.
            NavigationExecuteEstimatedTasksView(estimatingprogressdetails: estimatingprogressdetails,
                                                selecteduuids: $selecteduuids,
                                                reload: $reload,
                                                showview: $showview)
                .environmentObject(progressdetails)
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
            NavigationDetailsOneTaskRootView(selecteduuids: $selecteduuids)
                .environment(estimatingprogressdetails)
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                }
        }
    }
}

enum DestinationView: String, Identifiable {
    case taskview, executestimatedview, executenoestimatetasksview, estimatedview, firsttime, dryrunonetask
    var id: String { rawValue }
}
