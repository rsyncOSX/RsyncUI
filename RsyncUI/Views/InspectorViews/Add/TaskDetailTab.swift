//
//  TaskDetailTab.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import OSLog
import SwiftUI

extension TaskDetailTab {
    func clearSelection() {
        selecteduuids.removeAll()
        selectedconfig = nil
        newdata.updateview(nil)
        newdata.showsaveurls = false
        changesnapshotnum = false
        stringestimate = ""
    }

    func handleProfileChange() {
        newdata.resetForm()
        selecteduuids.removeAll()
        selectedconfig = nil
    }

    func handleSelectionChange() {
        if let configurations = rsyncUIdata.configurations {
            guard selecteduuids.count == 1 else {
                return
            }
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                selectedconfig = configurations[index]
                newdata.updateview(configurations[index])
                updateURLString()
            } else {
                selectedconfig = nil
                newdata.updateview(nil)
                stringestimate = ""
                newdata.showsaveurls = false
            }
        }
    }

    func updateURLString() {
        if selectedconfig?.task == SharedReference.shared.synchronize {
            let deeplinkurl = DeeplinkURL()
            let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "Default")
            stringestimate = urlestimate?.absoluteString ?? ""
        } else {
            stringestimate = ""
        }
    }

}


struct TaskDetailTab: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State var newdata = ObservableAddConfigurations()
    @State var selectedconfig: SynchronizeConfiguration?
    @State var changesnapshotnum: Bool = false
    @State var stringestimate: String = ""
    @State var showAddPopover: Bool = false
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // Only show toolbar items when this tab is active
        if selectedTab == .edit {
            ToolbarItem(placement: .navigation) {
                Button {
                    newdata.resetForm()
                    selectedconfig = nil
                    showAddPopover.toggle()
                }
                label: { Image(systemName: "plus") }
                .help("Quick add task")
                .sheet(isPresented: $showAddPopover) {
                    AddTaskSheet(rsyncUIdata: rsyncUIdata)
                        .padding()
                        .frame(minWidth: 600)

                }
    
            }
        }
    }
    
    var body: some View {
        TaskDetailView(rsyncUIdata: rsyncUIdata, newdata: $newdata, selectedconfig: $selectedconfig, changesnapshotnum: $changesnapshotnum, stringestimate: $stringestimate)
        .onUpdate { clearSelection() }
        .padding()
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .onAppear { handleSelectionChange() }
        .onChange(of: selecteduuids) { handleSelectionChange() }
        .toolbar { toolbarContent }
    }
}
