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
    @EnvironmentObject var errorhandling: ErrorHandling

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
            .onDeleteCommand(perform: { delete() })
            .sheet(isPresented: $presentsheetview) { viewoutput }

        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Show logs", comment: "Show button")) { showlog() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
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

    func select() {
        if let schedule = selectedschedule {
            if selecteduuids.contains(schedule.id) {
                selecteduuids.remove(schedule.id)
            } else {
                selecteduuids.insert(schedule.id)
            }
        }
    }

    /*
     func indexofselectedschedule() {
         if let schedule = selectedschedule,
            let schedules = rsyncOSXData.schedulesandlogs
         {
             if let index = schedules.firstIndex(of: schedule) {
                 // print(index)
             }
         }
     }
     */
    func delete() {
        _ = NotYetImplemented()
        /*
         // Send all selected UUIDs to mark for delete
         if let hiddenID = selectedconfig?.hiddenID {
             let delete = SingletaskPrimaryLogging(profile: rsyncOSXData.profile,
                                                   hiddenID: hiddenID,
                                                   configurations: rsyncOSXData.configurations,
                                                   scheduleConfigurations: rsyncOSXData.schedulesandlogs)
             delete.deleteselectedschedules(uuids: selecteduuids, hiddenID: hiddenID)
         }
         */
    }
}
