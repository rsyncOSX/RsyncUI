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

    var body: some View {
        ZStack {
            VStack {
                headingtitle

                if showeexecutestimatedview == false && showexecutenoestimateview == false &&
                    showexecutenoestiamteonetask == false
                {
                    TasksSheetstateView(selectedconfig: $selectedconfig,
                                        reload: $reload,
                                        selecteduuids: $selecteduuids,
                                        showeexecutestimatedview: $showeexecutestimatedview,
                                        showcompleted: $showcompleted,
                                        showexecutenoestimateview: $showexecutenoestimateview,
                                        showexecutenoestiamteonetask: $showexecutenoestiamteonetask,
                                        selection: $selection)
                }

                if showeexecutestimatedview == true && showexecutenoestimateview == false &&
                    showexecutenoestiamteonetask == false
                {
                    ExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                              reload: $reload,
                                              showeexecutestimatedview: $showeexecutestimatedview)
                        .onDisappear(perform: {
                            showcompleted = true
                        })
                }

                if showexecutenoestimateview == true {
                    ExecuteNoestimatedTasksView(selectedconfig: $selectedconfig,
                                                reload: $reload,
                                                selecteduuids: $selecteduuids,
                                                showcompleted: $showcompleted,
                                                showexecutenoestimateview: $showexecutenoestimateview)
                        .onDisappear(perform: {
                            showcompleted = true
                        })
                }

                if showexecutenoestiamteonetask == true {
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
