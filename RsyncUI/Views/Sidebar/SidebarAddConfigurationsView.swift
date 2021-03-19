//
//  AddConfigurationsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct SidebarAddConfigurationsView: View {
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    var body: some View {
        AddView(selectedprofile: $selectedprofile, reload: $reload)
    }
}
