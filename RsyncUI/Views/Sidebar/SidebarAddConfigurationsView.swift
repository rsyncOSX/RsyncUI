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
                    Text("Add config")
                }
            AddPreandPostView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text("Pre and post")
                }
            AddProfileView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text("Profile")
                }
        }
        .padding()
    }
}
