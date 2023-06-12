//
//  SidebarParametersView.swift
//  SidebarParametersView
//
//  Created by Thomas Evensen on 19/08/2021.
//

import SwiftUI

struct SidebarParametersView: View {
    @Binding var reload: Bool
    @StateObject var dataischanged = Dataischanged()

    var body: some View {
        TabView {
            RsyncParametersView(reload: $reload)
                .tabItem {
                    Text("Parameters")
                }
                .environmentObject(dataischanged)
            RsyncDefaultParametersView(reload: $reload)
                .tabItem {
                    Text("Default")
                }
                .environmentObject(dataischanged)
        }
        .padding()
    }
}

final class Dataischanged: ObservableObject {
    var dataischanged: Bool = false
}
