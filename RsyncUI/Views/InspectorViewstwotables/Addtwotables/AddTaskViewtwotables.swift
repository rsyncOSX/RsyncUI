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
    @Binding var selectedTab: InspectorTab
    @Binding var showinspector: Bool
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @FocusState var focusField: AddConfigurationField?
    
    @State var newdata = ObservableAddConfigurations()
    @State var selectedconfig: SynchronizeConfiguration?
    @State var changesnapshotnum: Bool = false
    @State var stringestimate: String = ""
    @State var showhelp: Bool = false
    @State var showAddPopover: Bool = false

    @State var presentglobaltaskview: Bool = false
    @State var confirmcopyandpaste: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HelpSectionView(showhelp: $showhelp,
                            whichhelptext: $newdata.whichhelptext,
                            deleteparameterpresent: deleteparameterpresent)

            taskListView
                .overlay {
                    if let config = rsyncUIdata.configurations, config.isEmpty {
                        ContentUnavailableView {
                            Label("There are no tasks added",
                                  systemImage: "doc.richtext.fill")
                        } description: {
                            Text("Select the + button on the toolbar to add a task")
                        }
                    }
                }
        }
        .inspector(isPresented: $showinspector) {
            inspectorView
                .inspectorColumnWidth(min: 400, ideal: 500, max: 600)
        }
        .sheet(isPresented: $showhelp) { helpSheetView }
        .onSubmit { handleSubmit() }
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .onChange(of: selecteduuids) {
            handleSelectionChange()
        }
        .toolbar { toolbarContent }
        .padding()
    }
}
