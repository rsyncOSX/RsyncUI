//
//  SidebarMultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct SidebarMultipletasksView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @State private var selectedconfig: Configuration?
    @Binding var reload: Bool

    // Show estimate when true, execute else
    @State var showestimateview: Bool = true
    @State private var selecteduuids = Set<UUID>()
    // Show completed
    @State private var showcompleted: Bool = false

    var body: some View {
        ZStack {
            VStack {
                headingtitle

                if showestimateview == true {
                    MultipletasksView(selectedconfig: $selectedconfig.onChange {},
                                      reload: $reload,
                                      selecteduuids: $selecteduuids,
                                      showestimateview: $showestimateview)
                }

                if showestimateview == false {
                    ExecuteEstimatedView(selecteduuids: $selecteduuids,
                                         reload: $reload,
                                         showestimateview: $showestimateview)
                        .environmentObject(OutputFromMultipleTasks())
                        .onDisappear(perform: {
                            showcompleted = true
                        })
                }
            }
            .padding()

            if showcompleted {
                AlertToast(type: .complete(Color.green),
                           title: Optional(NSLocalizedString("Completed",
                                                             comment: "settings")), subTitle: Optional(""))
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
            ImageRsync()

            VStack(alignment: .leading) {
                Text(NSLocalizedString("Multiple tasks", comment: "Execute tasks"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
    }
}
