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
    @State private var dataischanged = Dataischanged()

    var body: some View {
        TabView {
            RsyncParametersView(reload: $reload)
                .tabItem {
                    Text("Parameters")
                }
                .environment(dataischanged)
            RsyncDefaultParametersView(reload: $reload)
                .tabItem {
                    Text("Default")
                }
                .environment(dataischanged)
        }
        .padding()
    }
}

@Observable
final class Dataischanged {
    var dataischanged: Bool = false
}
