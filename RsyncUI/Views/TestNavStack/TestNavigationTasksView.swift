//
//  TestNavigationTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/11/2023.
//

import Observation
import OSLog
import SwiftUI

struct TestNavigationTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var progressdetails: ExecuteProgressDetails
    @Bindable var estimatingprogressdetails: EstimateProgressDetails
    @State private var estimatingstate = EstimatingState()
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var showview: TestDestinationView?
    // Filterstring
    @State private var filterstring: String = ""
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    @State var selectedconfig = Selectedconfig()
    // Double click, only for macOS13 and later
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            NavigationListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                doubleclick: $doubleclick
            )
            .frame(maxWidth: .infinity)
            .onChange(of: selecteduuids) {
                let selected = rsyncUIdata.configurations?.filter { config in
                    selecteduuids.contains(config.id)
                }
                if (selected?.count ?? 0) == 1 {
                    if let config = selected {
                        selectedconfig.config = config[0]
                    }
                } else {
                    selectedconfig.config = nil
                }
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    showview = .alltasksview
                } label: {
                    Image(systemName: "list.bullet")
                }
                .help("List tasks all profiles")
            }

            ToolbarItem {
                Button {
                    showview = .firsttime
                } label: {
                    Image(systemName: "list.bullet")
                }
                .help("Firsttime")
            }
        })
    }
}
