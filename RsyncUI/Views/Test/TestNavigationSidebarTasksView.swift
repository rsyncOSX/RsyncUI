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
    // Which view to show
    @State private var showview: TestDestinationView?
    @State private var showDetails: Bool = false

    var body: some View {
        NavigationStack {
            TestNavigationTasksView(estimatingprogressdetails: estimatingprogressdetails,
                                    reload: $reload,
                                    selecteduuids: $selecteduuids,
                                    showview: $showview)
                .environmentObject(progressdetails)
        }.navigationDestination(isPresented: $showDetails) {
            makeView(view: showview)
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
    func makeView(view: TestDestinationView?) -> some View {
        switch view {
        case .estimatedview:
            TestNavigationSummarizedAllDetailsView(selecteduuids: $selecteduuids,
                                                   showview: $showview,
                                                   estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [])
        case .firsttime:
            NavigationFirstTimeView()
        case .dryrunonetask:
            NavigationDetailsOneTaskRootView(selecteduuids: selecteduuids)
                .environment(estimatingprogressdetails)
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                    showview = nil
                }
        case .dryrunonetaskalreadyestimated:
            NavigationDetailsOneTask(selecteduuids: selecteduuids,
                                     estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [])
                .onDisappear {
                    showview = nil
                }
        case .alltasksview:
            NavigationAlltasksView()
                .onDisappear {
                    showview = nil
                }
        case .none:
            TestNavigationTasksView(estimatingprogressdetails: estimatingprogressdetails,
                                    reload: $reload,
                                    selecteduuids: $selecteduuids,
                                    showview: $showview)
                .environmentObject(progressdetails)
        }
    }
}

enum TestDestinationView: String, Identifiable {
    case estimatedview, firsttime, dryrunonetask, alltasksview,
         dryrunonetaskalreadyestimated
    var id: String { rawValue }
}
