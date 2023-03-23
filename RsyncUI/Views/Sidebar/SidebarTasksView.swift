//
//  SidebarMultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct SidebarTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedconfig: Configuration?
    @Binding var reload: Bool
    // Which sidebar function
    @Binding var selection: NavigationItem?

    @State var showeexecutEstimatedview: Bool = false
    @State var showexecuteNOEstimateview: Bool = false
    @State var showexecuteNOEstiamteONEtask: Bool = false

    @State private var selecteduuids = Set<UUID>()
    @State private var showcompleted: Bool = false

    enum Task: String, Identifiable {
        case taskview, executestimatedview, executenoestimatetasksview, executenoestimateonetaskview
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            VStack {
                headingtitle

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

            if showcompleted {
                AlertToast(type: .complete(Color.green),
                           title: Optional("Completed"), subTitle: Optional(""))
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showcompleted = false
                        }
                    })
            }
        }
    }

    @ViewBuilder
    func makeView(task: Task) -> some View {
        switch task {
        case .taskview:
            TasksView(selectedconfig: $selectedconfig,
                      reload: $reload,
                      selecteduuids: $selecteduuids,
                      showeexecutestimatedview: $showeexecutEstimatedview,
                      showexecutenoestimateview: $showexecuteNOEstimateview,
                      showexecutenoestiamteonetask: $showexecuteNOEstiamteONEtask,
                      selection: $selection)
        case .executestimatedview:
            ExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                      reload: $reload,
                                      showeexecutestimatedview: $showeexecutEstimatedview)
                .onDisappear(perform: {
                    showcompleted = true
                })
        case .executenoestimatetasksview:
            ExecuteNoestimatedTasksView(selectedconfig: $selectedconfig,
                                        reload: $reload,
                                        selecteduuids: $selecteduuids,
                                        showcompleted: $showcompleted,
                                        showexecutenoestimateview: $showexecuteNOEstimateview)
                .onDisappear(perform: {
                    showcompleted = true
                })
        case .executenoestimateonetaskview:
            ExecuteNoestimateOneTaskView(selectedconfig: $selectedconfig,
                                         reload: $reload,
                                         selecteduuids: $selecteduuids,
                                         showcompleted: $showcompleted,
                                         showexecutenoestiamteonetask: $showexecuteNOEstiamteONEtask)
                .onDisappear(perform: {
                    showcompleted = true
                })
        }
    }

    var headingtitle: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Synchronize")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
