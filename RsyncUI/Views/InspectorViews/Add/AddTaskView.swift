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
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @FocusState var focusField: AddConfigurationField?

    @State var newdata = ObservableAddConfigurations()
    @Binding var showAddPopover: Bool

    func onAdd(newdata: ObservableAddConfigurations) {
        Task { @MainActor in
            if await addConfig(newdata: newdata) {
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
        TaskForm(profile: $rsyncUIdata.profile, focusField: _focusField, newdata: $newdata, onUpdate: onUpdate)
        .padding()
        .onAppear { handleSelectionChange() }
        .onSubmit { handleSubmit() }
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .onChange(of: selecteduuids) { handleSelectionChange() }
        .sheet(isPresented: $showAddPopover) { AddTaskSheetView(onAdd: onAdd) }
    }
}
