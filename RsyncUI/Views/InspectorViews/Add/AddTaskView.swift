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
    @State var showAddPopover: Bool = false

    @State var presentglobaltaskview: Bool = false

    var body: some View {
        AddTaskContentView(updateButton: { updateButton },
                           trailingslash: { trailingslash },
                           synchronizeID: { synchronizeID },
                           catalogSectionView: { catalogSectionView },
                           remoteuserandserver: { remoteuserandserver },
                           snapshotView: { snapshotnum },
                           saveURLSection: { saveURLSection },
                           showSnapshot: selectedconfig?.task == SharedReference.shared.snapshot)
        .onAppear { handleSelectionChange() }
        .onSubmit { handleSubmit() }
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .onChange(of: selecteduuids) { handleSelectionChange() }
        .toolbar { toolbarContent }
    }
}
