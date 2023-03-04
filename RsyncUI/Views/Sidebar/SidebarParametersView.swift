//
//  SidebarParametersView.swift
//  SidebarParametersView
//
//  Created by Thomas Evensen on 19/08/2021.
//

import SwiftUI

struct SidebarParametersView: View {
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @State private var filterstring: String = ""

    var body: some View {
        TabView {
            RsyncParametersView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text("Parameters")
                }
            RsyncDefaultParametersView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text("Default")
                }
        }
        .padding()
        .searchable(text: $filterstring)
    }
}
