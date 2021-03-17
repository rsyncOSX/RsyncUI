//
//  ConfigurationLogsView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct ConfigurationLogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata

    @Binding var selectedconfig: Configuration?
    @State private var selectedschedule: ConfigurationSchedule?
    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    @State var presentsheetview = false

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig,
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        SchedulesList(selectedconfig: $selectedconfig,
                      selectedschedule: $selectedschedule,
                      selecteduuids: $selecteduuids)
            .sheet(isPresented: $presentsheetview) { viewoutput }

        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Show logs", comment: "Show button")) { showlog() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    var viewoutput: some View {
        DetailedLogView(config: $selectedconfig,
                        isPresented: $presentsheetview,
                        selectedconfig: $selectedconfig,
                        selectedlog: $selectedlog)
    }
}

extension ConfigurationLogsView {
    func showlog() {
        presentsheetview = true
    }
}
