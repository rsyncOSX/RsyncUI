//
//  AddConfigurationsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct SidebarAddConfigurationsView: View {
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    var body: some View {
        TabView {
            AddConfigurationView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text(NSLocalizedString("Add config", comment: "logsview"))
                }
            AddPostandPreView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text(NSLocalizedString("Pre and post", comment: "logsview"))
                }
        }
        .padding()
    }
}
