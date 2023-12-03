//
//  NavigationSidebarParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct NavigationSidebarParametersView: View {
    @Binding var reload: Bool

    var body: some View {
        NavigationStack {
            TabView {
                NavigationRsyncParametersView(reload: $reload)
                    .tabItem {
                        Text("Parameters")
                    }
                NavigationRsyncDefaultParametersView(reload: $reload)
                    .tabItem {
                        Text("Default")
                    }
            }
            .padding()
        }
    }
}
