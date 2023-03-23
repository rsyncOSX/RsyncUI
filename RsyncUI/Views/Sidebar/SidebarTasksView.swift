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

    @State var showeexecutestimatedview: Bool = false
    @State var showexecutenoestimateview: Bool = false
    @State var showexecutenoestiamteonetask: Bool = false

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

                if showeexecutestimatedview == false &&
                    showexecutenoestimateview == false &&
                    showexecutenoestiamteonetask == false
                {
                    makeView(task: .taskview)
                }
                if showeexecutestimatedview == true &&
                    showexecutenoestimateview == false &&
                    showexecutenoestiamteonetask == false
                {
                    makeView(task: .executestimatedview)
                }
                if showexecutenoestimateview == true {
                    makeView(task: .executenoestimatetasksview)
                }
                if showexecutenoestiamteonetask == true {
                    makeView(task: .executenoestimateonetaskview)
                }
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
                      showeexecutestimatedview: $showeexecutestimatedview,
                      showcompleted: $showcompleted,
                      showexecutenoestimateview: $showexecutenoestimateview,
                      showexecutenoestiamteonetask: $showexecutenoestiamteonetask,
                      selection: $selection)
        case .executestimatedview:
            ExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                      reload: $reload,
                                      showeexecutestimatedview: $showeexecutestimatedview)
                .onDisappear(perform: {
                    showcompleted = true
                })
        case .executenoestimatetasksview:
            ExecuteNoestimatedTasksView(selectedconfig: $selectedconfig,
                                        reload: $reload,
                                        selecteduuids: $selecteduuids,
                                        showcompleted: $showcompleted,
                                        showexecutenoestimateview: $showexecutenoestimateview)
                .onDisappear(perform: {
                    showcompleted = true
                })
        case .executenoestimateonetaskview:
            ExecuteNoestimateOneTaskView(selectedconfig: $selectedconfig,
                                         reload: $reload,
                                         selecteduuids: $selecteduuids,
                                         showcompleted: $showcompleted,
                                         showexecutenoestiamteonetask: $showexecutenoestiamteonetask)
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
