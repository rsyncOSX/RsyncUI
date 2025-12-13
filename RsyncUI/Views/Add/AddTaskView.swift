//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//
// swiftlint:disable line_length

import OSLog
import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case homecatalogs, globalchanges
    var id: String { rawValue }
}

struct AddTasks: Hashable, Identifiable {
    let id = UUID()
    var task: AddTaskDestinationView
}

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
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var addtaskpath: [AddTasks]

    @State var newdata = ObservableAddConfigurations()
    @State var selectedconfig: SynchronizeConfiguration?
    @State var changesnapshotnum: Bool = false
    @FocusState var focusField: AddConfigurationField?
    @State var confirmcopyandpaste: Bool = false
    @State var stringestimate: String = ""
    @State var showhelp: Bool = false

    var body: some View {
        NavigationStack(path: $addtaskpath) {
            HStack {
                VStack(alignment: .leading) {
                    addOrUpdateButton
                    VStack(alignment: .trailing) {
                        pickerselecttypeoftask.disabled(selectedconfig != nil)
                        trailingslash
                    }
                    .padding(.bottom, 10)

                    VStack(alignment: .leading) { synchronizeID }
                    catalogSectionView
                    VStack(alignment: .leading) { remoteuserandserver }
                        .disabled(selectedconfig?.task == SharedReference.shared.snapshot)

                    if selectedconfig?.task == SharedReference.shared.snapshot {
                        VStack(alignment: .leading) { snapshotnum }
                    }

                    saveURLSection
                }

                VStack(alignment: .leading) {
                    helpSection
                    taskListView
                }
            }
        }
        .sheet(isPresented: $showhelp) { helpSheetView }
        .onSubmit { handleSubmit() }
        .onAppear { handleOnAppear() }
        .onChange(of: rsyncUIdata.profile) { handleProfileChange() }
        .toolbar { toolbarContent }
        .navigationTitle("Add and update tasks: profile \(rsyncUIdata.profile ?? "Default")")
        .navigationDestination(for: AddTasks.self) { makeView(view: $0.task) }
        .padding()
    }
}
