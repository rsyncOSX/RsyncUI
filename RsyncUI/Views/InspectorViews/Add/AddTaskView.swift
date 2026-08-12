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
    enum Mode {
        case inspector
        case add
    }

    @Environment(\.dismiss) private var dismiss
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    var mode: Mode = .inspector

    @FocusState var focusField: AddConfigurationField?

    @State var newdata = ObservableAddConfigurations()
    @State var selectedconfig: SynchronizeConfiguration?
    
    @State var trailingslashoption: Bool = true
    
    @State var changesnapshotnum: Bool = false
    @State var stringestimate: String = ""

    @State var presentglobaltaskview: Bool = false

    var showSnapshot: Bool {
        selectedconfig?.task == SharedReference.shared.snapshot
    }

    var body: some View {
        switch mode {
        case .inspector:
            Form {
                synchronizeID

                catalogSectionView

                remoteuserandserver

                if showSnapshot {
                    snapshotnum
                }

                Button("URL for RsyncUI Widget", systemImage: "arrow.down") {
                    let data = WidgetURLstrings(urletimate: stringestimate)
                    Task { @MainActor in
                        await WriteWidgetsURLStringsJSON.write(data)
                    }
                }

                updateButton
            }
            .formStyle(.grouped)
            .padding()
            .onAppear { handleSelectionChange() }
            .onSubmit { handleSubmit() }
            .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
            .onChange(of: selecteduuids) { handleSelectionChange() }
        case .add:
            addTaskSheetView
        }
    }

    func dismissAddSheet() {
        dismiss()
    }
}
