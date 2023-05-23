//
//  ConfigurationsListSmall.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/05/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct ConfigurationsListSmall: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    // Alert for delete
    @State private var confirmationShown = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        configlist
    }

    var configlist: some View {
        List(selection: $selectedconfig) {
            ForEach(rsyncUIdata.configurations ?? []) { configurations in
                OneConfigSmall(config: configurations)
                    .tag(configurations)
            }
            .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
        }
    }
}
