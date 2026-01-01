//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import OSLog
import SwiftUI

enum AddConfigurationField: Hashable {
    case localcatalogField
    case remotecatalogField
    case remoteuserField
    case remoteserverField
    case synchronizeIDField
    case snapshotnumField
}

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct AddTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @FocusState var focusField: AddConfigurationField?

    @State var newdata = ObservableAddConfigurations()
    @State var selectedconfig: SynchronizeConfiguration?
    @State var changesnapshotnum: Bool = false
    @State var stringestimate: String = ""
    @State var showhelp: Bool = false
    @State var showAddPopover: Bool = false

    @State var presentglobaltaskview: Bool = false
    // Show Inspector view
    @State var showinspector: Bool = false
    // Show resulting rsync command
    @State var showcommand: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HelpSectionView(showhelp: $showhelp,
                            whichhelptext: $newdata.whichhelptext,
                            deleteparameterpresent: deleteparameterpresent)
                .padding()

            Divider()

            VStack(alignment: .center, spacing: 12) {
                if showcommand, let selectedconfig {
                    RsyncCommandView(config: selectedconfig)
                }
                Spacer()
            }
            .inspector(isPresented: $showinspector) {
                inspectorView
                    .inspectorColumnWidth(min: 400, ideal: 500, max: 600)
            }
            .padding()
        }
        .sheet(isPresented: $showhelp) { helpSheetView }
        .onSubmit { handleSubmit() }
        .onAppear { handleOnAppear() }
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .onChange(of: selecteduuids) {
            handleSelectionChange()
        }
        .toolbar { toolbarContent }
    }
}
