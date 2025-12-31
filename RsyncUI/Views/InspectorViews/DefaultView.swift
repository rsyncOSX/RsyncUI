//
//  DefaultView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

struct DefaultView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    var body: some View {
        TabView {
            AddTaskView(rsyncUIdata: rsyncUIdata)
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }

            RsyncParametersView(rsyncUIdata: rsyncUIdata)
                .tabItem {
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
            
            GlobalChangeTaskView(rsyncUIdata: rsyncUIdata)
                .tabItem {
                    Label("Global", systemImage: "gearshape")
                }
        }
    }
}
