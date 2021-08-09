//
//  ConfigurationsListSmall.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/05/2021.
//

import SwiftUI

struct ConfigurationsListSmall: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selectedconfig: Configuration?

    let forestimated = false

    var body: some View {
        VStack {
            configlist
        }
    }

    var configlist: some View {
        List(selection: $selectedconfig) {
            ForEach(rsyncUIdata.configurations ?? []) { configurations in
                OneConfigSmall(config: configurations)
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
        }
    }
}
