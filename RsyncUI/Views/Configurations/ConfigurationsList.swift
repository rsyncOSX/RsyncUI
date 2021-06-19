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
                                print("Trash")
                            } label: {
                                Label("Trash", systemImage: "delete.backward.fill")
                            }
                        }
                }
                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                // .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    // Non selectable
    var configlist: some View {
        Section(header: header) {
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
            if let configurations = rsyncUIdata.configurations {
                let sorted = configurations.sorted { conf1, conf2 in
                    if let days1 = conf1.dateRun?.en_us_date_from_string(),
                       let days2 = conf2.dateRun?.en_us_date_from_string()
                    {
                        return days1 > days2
                    }
                    return false
                }
                return sorted
            }
            return []
        } else {
            if let configurations = rsyncUIdata.filterconfigurations(searchText) {
                let sorted = configurations.sorted { conf1, conf2 in
                    if let days1 = conf1.dateRun?.en_us_date_from_string(),
                       let days2 = conf2.dateRun?.en_us_date_from_string()
                    {
                        return days1 > days2
                    }
                    return false
                }
                return sorted
            }
            return []
        }
    }

    var header: some View {
        HStack {
            Text(NSLocalizedString("Synchronize ID", comment: "ConfigurationsList"))
                .modifier(FixedTag(120, .center))
            Text(NSLocalizedString("Task", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .center))
            Text(NSLocalizedString("Local catalog", comment: "ConfigurationsList"))
                .modifier(FixedTag(180, .center))
            Text(NSLocalizedString("Remote catalog", comment: "ConfigurationsList"))
                .modifier(FixedTag(180, .center))
            Text(NSLocalizedString("Server", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .center))
            Text(NSLocalizedString("User", comment: "ConfigurationsList"))
                .modifier(FixedTag(35, .center))
            Text(NSLocalizedString("Days", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .trailing))
            Text(NSLocalizedString("Last", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .trailing))
        }
    }

    var footer: some View {
        Text(NSLocalizedString("Most recent updated tasks on top of list", comment: "ConfigurationsList") + "...")
            .foregroundColor(Color.blue)
    }

    func sometablefunc() {}
}
