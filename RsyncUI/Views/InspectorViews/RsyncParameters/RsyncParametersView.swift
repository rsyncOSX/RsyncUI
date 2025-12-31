//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State var parameters = ObservableParametersRsync()
    @State var selectedconfig: SynchronizeConfiguration?
    // Backup switch
    @State var backup: Bool = false
    // Present a help sheet
    @State var showhelp: Bool = false
    // Present arguments view
    @State var presentarguments: Bool = false
    // Show Inspector view
    @State var showinspector: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 12) {
                HelpSectionView(showhelp: $showhelp,
                                whichhelptext: $parameters.whichhelptext,
                                deleteparameterpresent: deleteparameterpresent)

                taskListView

                Spacer()
            }
            .sheet(isPresented: $showhelp) { helpSheetView }
            .inspector(isPresented: $showinspector) {
                inspectorView
                    .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
            }
            .onChange(of: rsyncUIdata.profile) {
                selectedconfig = nil
                // selecteduuids.removeAll()
                // done on Sidebar Main view
                parameters.setvalues(selectedconfig)
                backup = false
            }
            .toolbar { toolbarContent }
            .navigationTitle("Parameters for rsync: profile \(rsyncUIdata.profile ?? "Default")")
            .navigationDestination(isPresented: $presentarguments) {
                ArgumentsView(rsyncUIdata: rsyncUIdata)
            }
            .padding()
        }
    }
}
