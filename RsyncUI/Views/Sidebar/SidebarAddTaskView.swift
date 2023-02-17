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
    // Modale view
    @State private var modalview = false
    // Focus buttons from the menu
    @State private var focusprofiletask: Bool = false

    var body: some View {
        TabView {
            AddTaskView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem { Text("Add task") }
            AddPreandPostView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem { Text("Shell scripts") }
        }
        .padding()
        .focusedSceneValue(\.profiletask, $focusprofiletask)
        .sheet(isPresented: $modalview) {
            AddProfileView(selectedprofile: $selectedprofile,
                           reload: $reload,
                           modalview: $modalview)
        }

        if focusprofiletask { labelprofiletask }
    }

    var labelprofiletask: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                modalview = true
            })
    }
}
