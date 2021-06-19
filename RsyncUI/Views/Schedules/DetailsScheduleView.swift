//
//  DetailsScheduleView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2021.
//

import SwiftUI

struct DetailsScheduleView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @Binding var showdetails: Bool
    @Binding var selectedconfig: Configuration?
    @Binding var selecteduuids: Set<UUID>
    @State private var selectedschedule: ConfigurationSchedule?
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    // Datepicker
    @State private var selecteddate = Date()
    @State private var selectedscheduletype = EnumScheduleDatePicker.once

    // Alert for delete
    @State private var showAlertfordelete = false
    // Alert for select
    @State private var notifyselect = false

    var body: some View {
        HStack {
            Spacer()

            ZStack {
                VStack {
                    SelectedstartView(selecteddate: $selecteddate,
                                      selectedscheduletype: $selectedscheduletype)
                        .border(Color.gray)

                    SchedulesList(selectedconfig: $selectedconfig,
                                  selectedschedule: $selectedschedule,
                                  selecteduuids: $selecteduuids)
                        .border(Color.gray)
                }

                if notifyselect == true { selectschdule }
            }
            .padding()

            SchedulesDatePickerView(selecteddate: $selecteddate)

            Spacer()
        }

        Spacer()

        HStack {
            Button(NSLocalizedString("Add", comment: "Add button")) { addschedule() }
                .buttonStyle(PrimaryButtonStyle())

            Spacer()

            Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Change", comment: "Change button")) { change() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $showAlertfordelete) {
                    ChangeSchedulesView(selecteduuids: $selecteduuids,
                                        isPresented: $showAlertfordelete,
                                        reload: $reload,
                                        selectedprofile: $selectedprofile)
                }

            Button(NSLocalizedString("Return", comment: "RsyncParametersView")) {
                selectedconfig = nil
                showdetails = false
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    var selectschdule: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional(NSLocalizedString("Select a schedule", comment: "settings")), subTitle: Optional(""))
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    notifyselect = false
                }
            })
    }
}

extension DetailsScheduleView {
    func select() {
        if let schedule = selectedschedule {
            if selecteduuids.contains(schedule.id) {
                selecteduuids.remove(schedule.id)
            } else {
                selecteduuids.insert(schedule.id)
            }
        }
    }

    func setuuidforselectedschedule() {
        if let schedule = selectedschedule,
           let schedules = rsyncUIdata.schedulesandlogs
        {
            if let index = schedules.firstIndex(of: schedule) {
                if let id = rsyncUIdata.schedulesandlogs?[index].id {
                    selecteduuids.insert(id)
                }
            }
        }
    }

    func addschedule() {
        let addschedule = UpdateSchedules(profile: selectedprofile,
                                          scheduleConfigurations: rsyncUIdata.schedulesandlogs)
        let add = addschedule.add(selectedconfig?.hiddenID,
                                  selectedscheduletype,
                                  selecteddate)
        if add == true {
            reload = true
        }
        selecteduuids.removeAll()
    }

    func change() {
        if selecteduuids.count == 0 { setuuidforselectedschedule() }
        guard selecteduuids.count > 0 else {
            notifyselect = true
            return
        }
        showAlertfordelete = true
        // selecteduuids.removeAll() is done in sheetview
    }
}

enum Scheduletype: String {
    case once
    case daily
    case weekly
    case manuel
    case stopped
}
