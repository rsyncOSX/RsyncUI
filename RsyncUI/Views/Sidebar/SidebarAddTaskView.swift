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
    @State private var filterstring: String = ""

    var body: some View {
        TabView {
            AddTaskView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem { Text("Add task") }
            AddPreandPostView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem { Text("Shell scripts") }
        }
        .padding()
        .searchable(text: $filterstring)
    }
}
