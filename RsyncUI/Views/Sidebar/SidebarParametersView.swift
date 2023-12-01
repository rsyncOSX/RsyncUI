//
//  SidebarParametersView.swift
//  SidebarParametersView
//
//  Created by Thomas Evensen on 19/08/2021.
//

import Observation
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

@Observable
final class Dataischanged {
    var dataischanged: Bool = false
}
