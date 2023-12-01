//
//  SidebarAddTaskView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct SidebarAddTaskView: View {
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @Bindable var profilenames: Profilenames

    var body: some View {
        TabView {
            AddTaskView(selectedprofile: $selectedprofile, reload: $reload, profilenames: profilenames)
                .tabItem { Text("Add task") }

            AddPreandPostView(profilenames: profilenames, selectedprofile: $selectedprofile, reload: $reload)
                .tabItem { Text("Shell scripts") }
        }
        .padding()
    }
}
