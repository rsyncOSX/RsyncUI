//
//  RsyncParametersViewtwotables.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncParametersViewtwotables: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var showinspector: Bool
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
        VStack(alignment: .leading) {
            HelpSectionView(showhelp: $showhelp,
                            whichhelptext: $parameters.whichhelptext,
                            deleteparameterpresent: deleteparameterpresent)

            taskListView
                .overlay {
                    if let config = rsyncUIdata.configurations, config.isEmpty {
                        ContentUnavailableView {
                            Label("There are no tasks added",
                                  systemImage: "doc.richtext.fill")
                        } description: {
                            Text("Select the + button in EDIT tab on the toolbar to add a task")
                        }
                    }
                }
        }
        .inspector(isPresented: $showinspector) {
            inspectorView
                .inspectorColumnWidth(min: 400, ideal: 500, max: 600)
        }
        .sheet(isPresented: $showhelp) { helpSheetView }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
            // selecteduuids.removeAll()
            // done on Sidebar Main view
            parameters.setvalues(selectedconfig)
            backup = false
        }
        .onChange(of: selecteduuids) {
            handleSelectionChange()
        }
        .padding()
    }
}
