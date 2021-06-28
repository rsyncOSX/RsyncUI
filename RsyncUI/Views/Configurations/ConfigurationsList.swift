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
    }

    // selectable configlist
    var selecetableconfiglist: some View {
        Section(header: header, footer: footer) {
            List(selection: $selectedconfig) {
                ForEach(rsyncUIdata.configurations ?? []) { configurations in
                    OneConfigUUID(selecteduuids: $selecteduuids,
                                  inwork: $inwork,
                                  config: configurations)
                        .tag(configurations)
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
                ForEach(rsyncUIdata.configurations ?? []) { configurations in
                    OneConfig(forestimated: forestimated,
                              config: configurations)
                        .tag(configurations)
                }
                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
            }
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

    func sometablefunc() {}
}
