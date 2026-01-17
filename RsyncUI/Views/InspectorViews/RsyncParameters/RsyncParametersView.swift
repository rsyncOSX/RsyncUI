//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var showinspector: Bool

    @State var parameters = ObservableParametersRsync()
    @State var selectedconfig: SynchronizeConfiguration?
    // Backup switch
    @State var backup: Bool = false
    // Present a help sheet
    @State var showhelp: Bool = false
    // Present arguments view
    @State var presentarguments: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HelpSectionView(showhelp: $showhelp,
                            whichhelptext: $parameters.whichhelptext,
                            deleteparameterpresent: deleteparameterpresent)
                .padding()

            Divider()

            VStack(alignment: .center, spacing: 12) {
                Spacer()
            }
            .inspector(isPresented: $showinspector) {
                inspectorView
                    .inspectorColumnWidth(min: 400, ideal: 500, max: 600)
            }
            .padding()
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
    }
}
