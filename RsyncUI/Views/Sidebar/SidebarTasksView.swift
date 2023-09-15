//
//  SidebarTasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct SidebarTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedconfig: Configuration?
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var reload: Bool

    @StateObject var progressdetails = ExecuteProgressDetails()

    @State var showeexecutEstimatedview: Bool = false
    @State var showexecuteNOEstimateview: Bool = false
    // Timer values
    @State private var timervalue: Double = 600

    var actions: Actions

    enum Task: String, Identifiable {
        case taskview, executestimatedview, executenoestimatetasksview
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            VStack {
                if showeexecutEstimatedview == false &&
                    showexecuteNOEstimateview == false { makeView(task: .taskview) }

                if showeexecutEstimatedview == true &&
                    showexecuteNOEstimateview == false { makeView(task: .executestimatedview) }

                if showeexecutEstimatedview == false &&
                    showexecuteNOEstimateview == true { makeView(task: .executenoestimatetasksview) }
            }
            .padding()
        }
    }

    @ViewBuilder
    func makeView(task: Task) -> some View {
        switch task {
        case .taskview:
            // This is default main view
            TasksView(reload: $reload,
                      selecteduuids: $selecteduuids,
                      showeexecutestimatedview: $showeexecutEstimatedview,
                      showexecutenoestimateview: $showexecuteNOEstimateview,
                      actions: actions
            )
            .environmentObject(progressdetails)
        case .executestimatedview:
            // This view is activated for execution of estimated tasks and view
            // presents progress of synchronization of data.
            ExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                      reload: $reload,
                                      showeexecutestimatedview: $showeexecutEstimatedview)
                .environmentObject(progressdetails)
        case .executenoestimatetasksview:
            // Execute tasks, no estimation ahead of synchronization
            ExecuteNoestimatedTasksView(reload: $reload,
                                        selecteduuids: $selecteduuids,
                                        showexecutenoestimateview: $showexecuteNOEstimateview)
        }
    }
}
