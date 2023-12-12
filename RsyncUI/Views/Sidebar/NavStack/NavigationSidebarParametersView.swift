//
//  NavigationSidebarParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct NavigationSidebarParametersView: View {
    @Binding var reload: Bool

    var body: some View {
        NavigationStack {
            NavigationRsyncParametersView(reload: $reload)
        }
    }
}
