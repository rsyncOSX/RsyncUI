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

    var showSnapshot: Bool {
        selectedconfig?.task == SharedReference.shared.snapshot
    }

    var body: some View {
        Form {
            TrailingSlashPicker()
            SynchronizeIDSection()
            CatalogSection()
            RemoteSection()
            if showSnapshot {
                SnapshotNumberSection()
            }

            SaveURLSection()

            UpdateButton()
        }
        .formStyle(.grouped)
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
        .sheet(isPresented: $showAddPopover) { AddTaskSheetView() }
    }
}
