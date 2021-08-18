//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//

import SwiftUI

struct RsyncParameters2View: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var reload: Bool
    @Binding var showdetails: Bool
    @Binding var selectedconfig: Configuration?

    @State private var searchText: String = ""
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        ConfigurationsListNonSelectable(selectedconfig: $selectedconfig.onChange { opendetails() },
                                        selecteduuids: $selecteduuids,
                                        inwork: $inwork,
                                        searchText: $searchText,
                                        reload: $reload)
    }

    func opendetails() {
        if selectedconfig != nil {
            showdetails = true
        }
    }
}
