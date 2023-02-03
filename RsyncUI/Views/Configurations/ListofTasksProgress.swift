//
//  ListofTasksProgress.swift
//  RsynctUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct ListofTasksProgress: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations

    @Binding var selectedconfig: Configuration?
    // Used when selectable and starting progressview
    @Binding var selecteduuids: Set<UUID>
    @Binding var inwork: Int
    @Binding var searchText: String
    @Binding var reload: Bool
    @Binding var confirmdelete: Bool

    var body: some View {
        VStack {
            configlist
        }
        .searchable(text: $searchText)
    }

    var configlist: some View {
        Section(header: header) {
            List(selection: $selectedconfig) {
                ForEach(configurationssorted) { configurations in
                    OneConfigProgressView(selecteduuids: $selecteduuids,
                                          inwork: $inwork,
                                          config: configurations)
                        .tag(configurations)
                        .confirmationDialog(
                            NSLocalizedString("Delete configuration", comment: "")
                                + "?",
                            isPresented: $confirmdelete
                        ) {
                            Button("Delete") {
                                setuuidforselectedtask()
                                delete()
                                confirmdelete = false
                            }
                        }
                }
                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
            }
        }
    }

    var configurationssorted: [Configuration] {
        if searchText.isEmpty {
            return rsyncUIdata.configurations ?? []
        } else {
            return rsyncUIdata.filterconfigurations(searchText) ?? []
        }
    }

    var header: some View {
        HStack {
            Text("Synchronize ID")
                .modifier(FixedTag(120, .center))
            Text("Task")
                .modifier(FixedTag(80, .center))
            Text("Local catalog")
                .modifier(FixedTag(180, .center))
            Text("Remote catalog")
                .modifier(FixedTag(180, .center))
            Text("Server")
                .modifier(FixedTag(80, .center))
            Text("User")
                .modifier(FixedTag(35, .center))
            Text("Days")
                .modifier(FixedTag(80, .trailing))
            Text("Last")
                .modifier(FixedTag(80, .trailing))
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
