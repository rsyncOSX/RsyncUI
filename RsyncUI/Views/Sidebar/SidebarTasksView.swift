//
//  SidebarMultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct SidebarTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @StateObject var progressdetails = ExecuteProgressDetails()
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>
    @State var showeexecutEstimatedview: Bool = false
    @State var showexecuteNOEstimateview: Bool = false
    @State var showexecuteNOEstiamteONEtask: Bool = false
    // @State private var selecteduuids = Set<Configuration.ID>()
    @State private var reloadtasksviewlist: Bool = false
    // Timer values
    @State private var timervalue: Double = 600

    var actions: Actions

    enum Task: String, Identifiable {
        case taskview, executestimatedview, executenoestimatetasksview, executenoestimateonetaskview
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            VStack {
                if showeexecutEstimatedview == false &&
                    showexecuteNOEstimateview == false &&
                    showexecuteNOEstiamteONEtask == false { makeView(task: .taskview) }

                if showeexecutEstimatedview == true &&
                    showexecuteNOEstimateview == false &&
                    showexecuteNOEstiamteONEtask == false { makeView(task: .executestimatedview) }

                if showeexecutEstimatedview == false &&
                    showexecuteNOEstiamteONEtask == false &&
                    showexecuteNOEstimateview == true { makeView(task: .executenoestimatetasksview) }

                if showeexecutEstimatedview == false &&
                    showexecuteNOEstimateview == false &&
                    showexecuteNOEstiamteONEtask == true { makeView(task: .executenoestimateonetaskview) }
            }
            .padding()
        }
    }

    @ViewBuilder
    func makeView(task: Task) -> some View {
        switch task {
        case .taskview:
            TasksView(reload: $reload,
                      selecteduuids: $selecteduuids,
                      showeexecutestimatedview: $showeexecutEstimatedview,
                      showexecutenoestimateview: $showexecuteNOEstimateview,
                      showexecutenoestiamteonetask: $showexecuteNOEstiamteONEtask,
                      actions: actions,
                      reloadtasksviewlist: $reloadtasksviewlist)
                .environmentObject(progressdetails)
        case .executestimatedview:
            ExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                      reload: $reload,
                                      showeexecutestimatedview: $showeexecutEstimatedview)
                .onDisappear(perform: {
                    reloadtasksviewlist = true
                })
                .environmentObject(progressdetails)
        case .executenoestimatetasksview:
            ExecuteNoestimatedTasksView(reload: $reload,
                                        selecteduuids: $selecteduuids,
                                        showcompleted: $reloadtasksviewlist,
                                        showexecutenoestimateview: $showexecuteNOEstimateview)
                .onDisappear(perform: {
                    reloadtasksviewlist = true
                })
        case .executenoestimateonetaskview:
            ExecuteNoestimateOneTaskView(reload: $reload,
                                         selecteduuids: $selecteduuids,
                                         showcompleted: $reloadtasksviewlist,
                                         showexecutenoestiamteonetask: $showexecuteNOEstiamteONEtask)
                .onDisappear(perform: {
                    reloadtasksviewlist = true
                })
        }
    }
}
