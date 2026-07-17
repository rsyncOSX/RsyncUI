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

    @FocusState.Binding var focusField: AddConfigurationField?

    let validateAndUpdate: (ObservableAddConfigurations) async -> Bool
    let handleSubmit: (ObservableAddConfigurations) -> Void

    @State var newdata = ObservableAddConfigurations()
    @State var stringestimate: String = ""

    func onUpdate() {
        Task { @MainActor in
            _ = await validateAndUpdate(newdata)
        }
    }

    var body: some View {
        TaskForm(focusField: $focusField, newdata: $newdata, stringestimate: $stringestimate, onUpdate: onUpdate)
            .padding()
            .onAppear { handleSelectionChange() }
            .onSubmit { handleSubmit(newdata) }
            .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
            .onChange(of: selecteduuids) { handleSelectionChange() }
    }
}
