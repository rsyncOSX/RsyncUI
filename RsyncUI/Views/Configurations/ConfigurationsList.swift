//
//  ConfigurationsList.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import SwiftUI

struct ConfigurationsList: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata

    @Binding var selectedconfig: Configuration?
    // Used when selectable and starting progressview
    @Binding var selecteduuids: Set<UUID>
    @Binding var inwork: Int
    @Binding var searchText: String
    @Binding var reload: Bool

    // Alert for delete
    @State private var showAlertfordelete = false
    @State private var confirmdeleteselectedconfigurations = false

    // Either selectable configlist or not
    var selectable: Bool
    let forestimated = false

    var body: some View {
        VStack {
            if selectable {
                selecetableconfiglist
            } else {
                configlist
            }
        }
        .searchable(text: $searchText)
        .sheet(isPresented: $showAlertfordelete) {
            ConfirmDeleteConfigurationsView(isPresented: $showAlertfordelete,
                                            delete: $confirmdeleteselectedconfigurations,
                                            selecteduuids: $selecteduuids)
                .onDisappear {
                    delete()
                }
        }
    }

    // selectable configlist
    var selecetableconfiglist: some View {
        Section(header: header, footer: footer) {
            List(selection: $selectedconfig) {
                ForEach(configurationssorted) { configurations in
                    OneConfigUUID(selecteduuids: $selecteduuids,
                                  inwork: $inwork,
                                  config: configurations)
                        .tag(configurations)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                setuuidforselectedtask()
                                showAlertfordelete = true
                            } label: {
                                Label("Trash", systemImage: "delete.backward.fill")
                            }
                        }
                }
                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
            }
        }
    }

    // Non selectable
    var configlist: some View {
        Section(header: header, footer: footer) {
            List(selection: $selectedconfig) {
                ForEach(configurationssorted) { configurations in
                    OneConfig(forestimated: forestimated,
                              config: configurations)
                        .tag(configurations)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                print("shortcut")
                            } label: {
                                Label("Execute", systemImage: "play.square.fill")
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

    var footer: some View {
        Text("Most recent updated tasks on top of list")
            .foregroundColor(Color.blue)
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
        guard confirmdeleteselectedconfigurations == true else {
            selecteduuids.removeAll()
            return
        }
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncUIdata.rsyncdata?.profile,
                                 configurations: rsyncUIdata.rsyncdata?.configurationData.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        reload = true
    }
}
