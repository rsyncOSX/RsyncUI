//
//  SidebarParametersView.swift
//  SidebarParametersView
//
//  Created by Thomas Evensen on 19/08/2021.
//

import SwiftUI

struct SidebarParametersView: View {
    @Binding var reload: Bool

    var body: some View {
        TabView {
            RsyncParametersView(reload: $reload)
                .tabItem {
                    Text("Parameters")
                }
            RsyncDefaultParametersView(reload: $reload)
                .tabItem {
                    Text("Default")
                }
        }
        .padding()
    }
}

final class Dataischanged: ObservableObject {
    var dataischanged: Bool = false
}
