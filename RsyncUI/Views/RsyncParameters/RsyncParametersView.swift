//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State var parameters = ObservableParametersRsync()
    @State var selectedconfig: SynchronizeConfiguration?
    // Backup switch
    @State var backup: Bool = false
    // Present a help sheet
    @State var showhelp: Bool = false
    // Present arguments view
    @State var presentarguments: Bool = false

    var body: some View {
        NavigationStack {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .center, spacing: 12) {
                    HelpSectionView(showhelp: $showhelp,
                                    whichhelptext: $parameters.whichhelptext,
                                    deleteparameterpresent: deleteparameterpresent)
                    taskListView

                    Spacer()
                }
                if showhelp {
                    helpSheetView
                } else {
                    inspectorView
                }
            }
        }
        .onAppear {
            if selecteduuids.count > 0 {
                // Reset preselected tasks, must do a few seconds timout
                // before clearing it out
                Task {
                    try await Task.sleep(seconds: 2)
                    selecteduuids.removeAll()
                }
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
            // selecteduuids.removeAll()
            // done on Sidebar Main view
            parameters.setvalues(selectedconfig)
            backup = false
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    presentarguments = true
                } label: {
                    Image(systemName: "command")
                }
                .help("Show arguments")
            }
        })
        .navigationTitle("Parameters for rsync: profile \(rsyncUIdata.profile ?? "Default")")
        .navigationDestination(isPresented: $presentarguments) {
            ArgumentsView(rsyncUIdata: rsyncUIdata)
        }
        .padding()
    }
}
