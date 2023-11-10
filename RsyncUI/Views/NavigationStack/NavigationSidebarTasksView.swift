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

    @State var showeexecutEstimatedview: Bool = false
    @State var showexecuteNOEstimateview: Bool = false
    @State var showestimatedview: Bool = false
    // Timer values
    @State private var timervalue: Double = 600
    // Start execution
    @State private var focusstartexecution: Bool = false

    enum Task: String, Identifiable {
        case taskview, executestimatedview, executenoestimatetasksview, estimatedview
        var id: String { rawValue }
    }

    var body: some View {
        if showeexecutEstimatedview == false &&
            showexecuteNOEstimateview == false &&
            showestimatedview == false
        { makeView(task: .taskview) }

        if showeexecutEstimatedview == true &&
            showexecuteNOEstimateview == false &&
            showestimatedview == false
        { makeView(task: .executestimatedview) }

        if showeexecutEstimatedview == false &&
            showexecuteNOEstimateview == true &&
            showestimatedview == false
        { makeView(task: .executenoestimatetasksview) }
        if showeexecutEstimatedview == false &&
            showexecuteNOEstimateview == false &&
            showestimatedview == true
        { makeView(task: .estimatedview) }
    }

    @ViewBuilder
    func makeView(task: Task) -> some View {
        switch task {
        case .taskview:
            // This is default main view
            NavigationTasksView(reload: $reload,
                                selecteduuids: $selecteduuids,
                                showeexecutestimatedview: $showeexecutEstimatedview,
                                showexecutenoestimateview: $showexecuteNOEstimateview,
                                showestimatedview: $showestimatedview,
                                estimatingprogresscount: estimatingprogresscount)
                .environmentObject(progressdetails)
                .padding()
        case .executestimatedview:
            // This view is activated for execution of estimated tasks and view
            // presents progress of synchronization of data.
            ExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                      reload: $reload,
                                      showeexecutestimatedview: $showeexecutEstimatedview)
                .environmentObject(progressdetails)
                .padding()
        case .executenoestimatetasksview:
            // Execute tasks, no estimation ahead of synchronization
            ExecuteNoestimatedTasksView(reload: $reload,
                                        selecteduuids: $selecteduuids,
                                        showexecutenoestimateview: $showexecuteNOEstimateview)
                .padding()

        case .estimatedview:
            NavigationSummarizedAllDetailsView(estimatedlist: estimatingprogresscount.getestimatedlist() ?? [])
        }
    }
}
