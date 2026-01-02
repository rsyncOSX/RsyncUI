//
//  AddTaskViewtwotables.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import OSLog
import SwiftUI

struct AddTaskViewtwotables: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTabtwotables

    @FocusState var focusField: AddConfigurationField?
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()

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

    @State var confirmcopyandpaste: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HelpSectionView(showhelp: $showhelp,
                            whichhelptext: $newdata.whichhelptext,
                            deleteparameterpresent: deleteparameterpresent)

            taskListView

            if showcommand, let selectedconfig {
                RsyncCommandView(config: selectedconfig)
            }
        }
        .inspector(isPresented: $showinspector) {
            inspectorView
                .inspectorColumnWidth(min: 400, ideal: 500, max: 600)
        }
        .sheet(isPresented: $showhelp) { helpSheetView }
        .onSubmit { handleSubmit() }
        .onAppear { handleOnAppear() }
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .onChange(of: selecteduuids) {
            handleSelectionChange()
        }
        .toolbar { toolbarContent }
        .padding()
    }
}
