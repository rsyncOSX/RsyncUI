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

    var body: some View {
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
            }
        }
        .padding()
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
