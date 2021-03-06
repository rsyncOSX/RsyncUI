//
//  SidebarAddView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SidebarAddView: View {
    @EnvironmentObject var errorhandling: ErrorHandling
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    var body: some View {
        TabView {
            AddConfigurationsView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text(NSLocalizedString("Configurations", comment: "user settings"))
                }
            SchedulesView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text(NSLocalizedString("Schedules", comment: "user settings"))
                }
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
        .padding()
    }
}
