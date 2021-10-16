//
//  ConfigurationsListNonSelectable.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct ConfigurationsListNonSelectable: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations

    @Binding var selectedconfig: Configuration?
    // Used when selectable and starting progressview
    @Binding var selecteduuids: Set<UUID>
    @Binding var inwork: Int
    @Binding var searchText: String
    @Binding var reload: Bool
    // Alert for delete
    @State private var confirmationShown = false

    let forestimated = false

    var body: some View {
        VStack {
            configlist
        }
        .searchable(text: $searchText)
    }

    // Non selectable
    var configlist: some View {
        // Section(header: header, footer: footer) {
        Section(header: header) {
            List(selection: $selectedconfig) {
                ForEach(configurationssorted) { configurations in
                    OneConfig(forestimated: forestimated,
                              config: configurations)
                        .tag(configurations)
                    /*
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                print("shortcut")
                            } label: {
                                Label("Execute", systemImage: "play.square.fill")
                            }
                        }
                     */
                }
                .listRowInsets(.init(top: 2, leading: 40, bottom: 2, trailing: 0))
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
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncUIdata.configurationsfromstore?.profile,
                                 configurations: rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        reload = true
    }
}
