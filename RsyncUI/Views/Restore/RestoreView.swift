//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//

import SwiftUI

struct RestoreView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @StateObject var snapshotdata = SnapshotData()
    @Binding var selectedconfig: Configuration?

    @State private var snapshotrecords: Logrecordsschedules?
    @State private var selecteduuids = Set<UUID>()
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    // If not a snapshot
    @State private var notsnapshot = false

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange {},
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Restore", comment: "Delete")) {}
                .buttonStyle(AbortButtonStyle())

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
    }
}

extension RestoreView {
    func abort() {}
}
