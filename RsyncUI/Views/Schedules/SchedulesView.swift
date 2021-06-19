//
//  SchedulesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/03/2021.
//

import SwiftUI

struct SchedulesView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @Binding var showdetails: Bool
    @Binding var selectedconfig: Configuration?
    @Binding var selecteduuids: Set<UUID>
    // Not used but requiered in parameter
    @State private var inwork = -1

    let selectable = false

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange { opendetails() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: selectable)
    }

    func opendetails() {
        if selectedconfig != nil {
            showdetails = true
        }
    }
}
