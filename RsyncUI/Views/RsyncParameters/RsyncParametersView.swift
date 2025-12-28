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
    // @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    // @State private var selectedrsynccommand = RsyncCommand.synchronize_data
    // Focus buttons from the menu
    @State var focusaborttask: Bool = false
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
                    helpSection
                    taskListView
                }
                if showhelp {
                    helpSheetView
                } else {
                    inspectorView
                }
            }
            HStack {
                /*
                VStack(alignment: .leading) {
                    
                    if notifydataisupdated {
                        ConditionalGlassButton(
                            systemImage: "arrow.down",
                            text: "Update",
                            helpText: "Update parameters"
                        ) {
                            saveRsyncParameters()
                            selecteduuids.removeAll()
                        }
                        .disabled(selectedconfig == nil)
                        .padding(.bottom, 10)

                    } else {
                        ConditionalGlassButton(
                            systemImage: "plus",
                            text: "Add",
                            helpText: "Save parameters"
                        ) {
                            saveRsyncParameters()
                        }
                        .disabled(selectedconfig == nil)
                        .padding(.bottom, 10)
                    }
                }

                Spacer()
*/
            }

            Spacer()
            if focusaborttask { labelaborttask }
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
        .focusedSceneValue(\.aborttask, $focusaborttask)
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
