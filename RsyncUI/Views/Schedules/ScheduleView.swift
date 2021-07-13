//
//  DetailsScheduleView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2021.
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata

    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selecteduuids = Set<UUID>()
    @State private var selectedschedule: ConfigurationSchedule?
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    // Datepicker
    @State private var selecteddate = Date()
    @State private var selectedscheduletype = EnumScheduleTypePicker.once
    // Alert for delete
    @State private var showAlertfordelete = false
    // Alert for select
    @State private var notifyselect = false

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        ScheduleTypePicker(selecteddate: $selecteddate,
                                           selectedscheduletype: $selectedscheduletype)

                        ScheduleDatePicker(selecteddate: $selecteddate)
                            .frame(width: 150)
                    }

                    SchedulesList(selectedconfig: $selectedconfig,
                                  selectedschedule: $selectedschedule,
                                  selecteduuids: $selecteduuids)
                }

                VStack(alignment: .leading) {
                    ConfigurationsListSmall(selectedconfig: $selectedconfig)
                }
            }

            if notifyselect == true { selectschdule }
        }
        .padding()

        Spacer()

        HStack {
            Button("Add") { addschedule() }
                .buttonStyle(PrimaryButtonStyle())

            Spacer()

            Button("Select") { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Change") { change() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $showAlertfordelete) {
                    ChangeSchedulesView(selecteduuids: $selecteduuids,
                                        isPresented: $showAlertfordelete,
                                        reload: $reload,
                                        selectedprofile: $selectedprofile)
                }
        }
    }

    var selectschdule: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional("Select a schedule"), subTitle: Optional(""))
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    notifyselect = false
                }
            })
    }
}

extension ScheduleView {
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
        // selecteduuids.removeAll()
    }

    func change() {
        if selecteduuids.count == 0 { setuuidforselectedschedule() }
        guard selecteduuids.count > 0 else {
            notifyselect = true
            return
        }
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
