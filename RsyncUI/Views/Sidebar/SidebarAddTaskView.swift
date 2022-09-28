//
//  AddConfigurationsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct SidebarAddTaskView: View {
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    var body: some View {
        TabView {
            AddTaskView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text("Add task")
                }
            AddPreandPostView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text("Shell scripts")
                }
            AddProfileView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text("Profiles")
                }
        }
        .padding()
    }
}
