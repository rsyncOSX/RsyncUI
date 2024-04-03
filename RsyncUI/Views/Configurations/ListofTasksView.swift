//
//  ListofTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/05/2023.
//

import SwiftUI

struct ListofTasksView: View {
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                    filterstring: $filterstring,
                                    profile: profile,
                                    configurations: configurations)
            .searchable(text: $filterstring)
    }
}
