//
//  ListofTasksLightView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct ListofTasksLightView: View {
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @State private var filterstring: String = ""
    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                    filterstring: $filterstring,
                                    profile: profile,
                                    configurations: configurations)
    }
}
