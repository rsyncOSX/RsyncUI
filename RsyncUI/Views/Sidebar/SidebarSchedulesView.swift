//
//  SchedulesTab.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 07/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct SidebarSchedulesView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata

    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedschedule: ConfigurationSchedule?
    @State private var selecteduuids = Set<UUID>()

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false

    // Datepicker
    @State private var selecteddate = Date()
    @State private var selectedscheduletype = EnumScheduleDatePicker.once

    // Alert for delete
    @State private var showAlertfordelete = false

    var body: some View {
        VStack {
            headingtitle

            ConfigurationsList(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)
            HStack {
                Spacer()

                SchedulesDatePickerView(selecteddate: $selecteddate,
                                        selectedscheduletype: $selectedscheduletype)

                SchedulesList(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() },
                              selectedschedule: $selectedschedule,
                              selecteduuids: $selecteduuids)

                Spacer()
            }
            .padding()
        }

        // Buttons in right down corner
        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Add", comment: "Add button")) { addschedule() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Stop", comment: "Stop button")) { stop() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Delete", comment: "Delete button")) { delete() }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $showAlertfordelete) {
                    DeleteSchedulesView(selecteduuids: $selecteduuids,
                                        isPresented: $showAlertfordelete,
                                        reload: $reload,
                                        selectedprofile: $selectedprofile)
                }
        }.padding()
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text(NSLocalizedString("Schedules", comment: "SidebarLogsView"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}

extension SidebarSchedulesView {
    func select() {
        if let schedule = selectedschedule {
            if selecteduuids.contains(schedule.id) {
                selecteduuids.remove(schedule.id)
            } else {
                selecteduuids.insert(schedule.id)
            }
        }
    }

    func indexofselectedschedule() {
        if let schedule = selectedschedule,
           let schedules = rsyncOSXData.schedulesandlogs
        {
            if let index = schedules.firstIndex(of: schedule) {
                print(index)
            }
        }
    }

    func addschedule() {
        let addschedule = UpdateSchedules(profile: selectedprofile,
                                          scheduleConfigurations: rsyncOSXData.schedulesandlogs)
        let add = addschedule.add(selectedconfig?.hiddenID,
                                  selectedscheduletype,
                                  selecteddate)
        if add == true {
            reload = true
        }
    }

    func stop() {
        let stopschedule = UpdateSchedules(profile: selectedprofile,
                                           scheduleConfigurations: rsyncOSXData.schedulesandlogs)
        stopschedule.stop(uuids: selecteduuids)
        reload = true
    }

    func delete() {
        guard selecteduuids.count > 0 else { return }
        showAlertfordelete = true
    }
}

enum Scheduletype: String {
    case once
    case daily
    case weekly
    case manuel
    case stopped
}
