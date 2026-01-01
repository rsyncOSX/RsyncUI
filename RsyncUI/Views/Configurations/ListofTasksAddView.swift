//
//  ListofTasksAddView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/08/2023.
//

import SwiftUI

struct ListofTasksAddView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var confirmdelete: Bool = false
    @State var confirmcopyandpaste: Bool = false
    @State var newdata = ObservableAddConfigurations()

    var body: some View {
        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                    configurations: rsyncUIdata.configurations)
            .confirmationDialog(selecteduuids.count == 1 ? "Delete 1 configuration" :
                "Delete \(selecteduuids.count) configurations",
                isPresented: $confirmdelete) {
                    Button("Delete") {
                        delete()
                        confirmdelete = false
                    }
            }
            .onDeleteCommand {
                confirmdelete = true
            }
            .copyable(copyitems.filter { selecteduuids.contains($0.id) })
                        .pasteDestination(for: CopyItem.self) { handlePaste($0) }
                        validator: { $0.filter { $0.task != SharedReference.shared.snapshot } }
                        .confirmationDialog(confirmationMessage, isPresented: $confirmcopyandpaste) {
                            Button("Copy") { handleCopyConfirmation() }
                        }
    }
    
    var copyitems: [CopyItem] {
        rsyncUIdata.configurations?.map { CopyItem(id: $0.id, task: $0.task) } ?? []
    }

    var confirmationMessage: String {
        let count = newdata.copyandpasteconfigurations?.count ?? 0
        return count == 1 ? "Copy 1 configuration" : "Copy \(count) configurations"
    }

    func delete() {
        if let configurations = rsyncUIdata.configurations {
            let deleteconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            deleteconfigurations.deleteconfigurations(selecteduuids)
            selecteduuids.removeAll()
            rsyncUIdata.configurations = deleteconfigurations.configurations
        }
    }
    
    func handlePaste(_ items: [CopyItem]) {
        newdata.prepareCopyAndPasteTasks(items, rsyncUIdata.configurations ?? [])
        guard items.count > 0 else { return }
        confirmcopyandpaste = true
    }

    func handleCopyConfirmation() {
        confirmcopyandpaste = false
        rsyncUIdata.configurations = newdata.writeCopyAndPasteTasks(rsyncUIdata.profile, rsyncUIdata.configurations ?? [])
        if SharedReference.shared.duplicatecheck, let configurations = rsyncUIdata.configurations {
            VerifyDuplicates(configurations)
        }
    }
}
