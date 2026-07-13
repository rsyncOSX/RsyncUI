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

    var id: String {
        rawValue
    }

    var description: String {
        rawValue.localizedLowercase
    }
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
    @Binding var showAddPopover: Bool

    @State var presentglobaltaskview: Bool = false

    func onAdd() {
        Task { @MainActor in
            if await addConfig() {
                showAddPopover = false
            }
        }
    }

    func onUpdate() {
        Task { @MainActor in
            _ = await validateAndUpdate()
        }
    }

    var body: some View {
        TaskForm(mode: .update, rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids, newdata: $newdata, selectedconfig: $selectedconfig, changesnapshotnum: $changesnapshotnum, stringestimate: $stringestimate, onUpdate: onUpdate)
        .padding()
        .onAppear { handleSelectionChange() }
        .onSubmit { handleSubmit() }
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .onChange(of: selecteduuids) { handleSelectionChange() }
        .onChange(of: showAddPopover) { _, isPresented in
            if isPresented {
                newdata.resetForm()
                selectedconfig = nil
            }
        }
        .sheet(isPresented: $showAddPopover) { AddTaskSheetView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids, newdata: $newdata, selectedconfig: $selectedconfig, changesnapshotnum: $changesnapshotnum, stringestimate: $stringestimate, presentglobaltaskview: $presentglobaltaskview, onAdd: onAdd) }
    }
}
