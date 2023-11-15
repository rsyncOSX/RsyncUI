//
//  TestNavigationSidebarTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/11/2023.
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
    }

    @ViewBuilder
    func makeView(view: TestDestinationView?) -> some View {
        switch view {
        case .firsttime:
            NavigationFirstTimeView()
        case .alltasksview:
            NavigationAlltasksView()
                .onDisappear {
                    showview = nil
                }
        case .none:
            Text("")
        }
    }
}

enum TestDestinationView: String, Identifiable {
    case firsttime, alltasksview
    var id: String { rawValue }
}
