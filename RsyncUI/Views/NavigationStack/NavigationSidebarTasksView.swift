//
//  NavigationSidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

struct NavigationSidebarTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var selectedconfig: Configuration?
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var reload: Bool
    @State private var estimatingprogresscount = EstimateProgressDetails()
    @StateObject private var progressdetails = ExecuteProgressDetails()
    // Which view to show
    @State private var showview: DestinationView = .taskview
    @State private var showDetails: Bool = false

    var body: some View {
        NavigationStack {
            NavigationTasksView(reload: $reload,
                                selecteduuids: $selecteduuids,
                                showview: $showview,
                                estimatingprogresscount: estimatingprogresscount)
                .environmentObject(progressdetails)
        }.navigationDestination(isPresented: $showDetails) {
            makeView(view: showview)
        }
        .onChange(of: showview) {
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
        case .taskview:
            // This is default main view
            NavigationTasksView(reload: $reload,
                                selecteduuids: $selecteduuids,
                                showview: $showview,
                                estimatingprogresscount: estimatingprogresscount)
                .environmentObject(progressdetails)
        case .executestimatedview:
            // This view is activated for execution of estimated tasks and view
            // presents progress of synchronization of data.
            NavigationExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                                reload: $reload,
                                                showview: $showview)
                .environmentObject(progressdetails)
        case .executenoestimatetasksview:
            // Execute tasks, no estimation ahead of synchronization
            NavigationExecuteNoestimatedTasksView(reload: $reload,
                                                  selecteduuids: $selecteduuids,
                                                  showview: $showview)
        case .estimatedview:
            NavigationSummarizedAllDetailsView(showview: $showview,
                                               estimatedlist: estimatingprogresscount.getestimatedlist() ?? [])
        case .firsttime:
            FirsttimeView()
        case .dryrunonetask:
            NavigationDetailsOneTaskView(selecteduuids: $selecteduuids)
                .environment(estimatingprogresscount)
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogresscount.getestimatedlist())
                }
        }
    }
}

enum DestinationView: String, Identifiable {
    case taskview, executestimatedview, executenoestimatetasksview, estimatedview, firsttime, dryrunonetask
    var id: String { rawValue }
}
