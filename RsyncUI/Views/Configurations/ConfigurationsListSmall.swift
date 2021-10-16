//
//  ConfigurationsListSmall.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/05/2021.
//

import SwiftUI

struct ConfigurationsListSmall: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool

    // Alert for delete
    @State private var confirmationShown = false
    @State private var selecteduuids = Set<UUID>()

    let forestimated = false

    var body: some View {
        configlist
    }

    var configlist: some View {
        List(selection: $selectedconfig) {
            ForEach(rsyncUIdata.configurations ?? []) { configurations in
                OneConfigSmall(config: configurations)
                    .tag(configurations)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            confirmationShown = true
                        } label: {
                            Label("Trash", systemImage: "delete.backward.fill")
                        }
                    }
                    .confirmationDialog(
                        NSLocalizedString("Delete configuration", comment: "")
                            + "?",
                        isPresented: $confirmationShown
                    ) {
                        Button("Delete") {
                            setuuidforselectedtask()
                            delete()
                        }
                    }
            }
            .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
        }
    }

    func setuuidforselectedtask() {
        selecteduuids.removeAll()
        if let sel = selectedconfig,
           let index = rsyncUIdata.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncUIdata.configurations?[index].id {
                selecteduuids.insert(id)
            }
        }
    }

    func delete() {
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncUIdata.configurationsfromstore?.profile,
                                 configurations: rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        reload = true
    }
}
