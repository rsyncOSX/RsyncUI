//
//  AddSchedule.swift
//  Calendar
//
//  Created by Thomas Evensen on 25/03/2025.
//

import OSLog
import SwiftUI

struct AddSchedule: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var schedules: ObservableSchedules

    @Binding var selectedprofileID: ProfilesnamesRecord.ID?
    @Binding var dateAdded: String
    @Binding var dateRun: String
    @Binding var istappeddayint: Int
    @Binding var date: Date

    @State private var schedule: String = ScheduleType.once.rawValue
    @State private var dateRunMonth: String = Date.now.en_string_month_from_date()
    @State private var dateRunHour: String = ""

    private var plannedRun: String {
        dateRunMonth + " " + dateRunHour
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                profiles

                pickerselecttypeoftask

                Image(systemName: "figure.run")
                    .font(.title)
                    .imageScale(.small)
                    .foregroundStyle(.blue)

                TextField("", text: $dateRunMonth)
                    .frame(width: 100)

                EditValueErrorScheme(
                    50,
                    "",
                    $dateRunHour,
                    schedules.verifynextschedule(plannednextschedule: plannedRun)
                )
                .foregroundStyle(schedules.verifynextschedule(plannednextschedule: plannedRun)
                    ? Color.white : Color.red)

                ConditionalGlassButton(
                    systemImage: "arrow.trianglehead.clockwise",
                    helpText: "Reset to current date"
                ) {
                    dateRunMonth = Date.now.en_string_month_from_date()
                    dateRunHour = hournow
                    istappeddayint = 0
                }

                Spacer()

                ConditionalGlassButton(
                    systemImage: "plus",
                    helpText: "Add schedule"
                ) {
                    let profile: String? = if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.id == selectedprofileID }) {
                        rsyncUIdata.validprofiles[index].profilename
                    } else { nil }

                    guard schedules.verifynextschedule(plannednextschedule: plannedRun) else {
                        return
                    }

                    guard schedules.appendSchedule(profile: profile, dateRun: plannedRun, schedule: schedule) else {
                        return
                    }

                    date = Date.now
                    istappeddayint = 0
                    schedules.lastdateinnextmonth = schedules.computelastdateinnextmonth()

                    Task { @MainActor in
                        await WriteSchedule.write(schedules.scheduleDataForPersistence())
                    }
                }
                .disabled(schedules.validPlannedScheduleDate(plannedRun) == nil)
            }
            .padding()
        }
        .onChange(of: dateRun) {
            let date = dateRun.en_date_from_string()
            dateRunMonth = date.en_string_month_from_date()
            dateRunHour = date.en_string_hour_from_date()
        }
        .onAppear {
            dateRunHour = hournow
        }
    }

    var pickerselecttypeoftask: some View {
        Picker("",
               selection: $schedule) {
            ForEach(ScheduleType.allCases) { Text($0.description)
                .tag($0.rawValue)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 80)
    }

    var profiles: some View {
        Picker("", selection: $selectedprofileID) {
            Text("Default")
                .tag(nil as ProfilesnamesRecord.ID?)
            ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                Text(profile.profilename)
                    .tag(profile.id)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 120)
    }

    var hournow: String {
        var datecomponents = DateComponents()
        datecomponents.minute = Date.now.minuteInt + 5
        datecomponents.hour = Date.now.hourInt
        datecomponents.day = Date.now.dayInt
        datecomponents.year = Date.now.yearInt
        datecomponents.month = Date.now.monthInt
        let calendar = Calendar.current
        return calendar.date(from: datecomponents)?.en_string_hour_from_date() ?? "08:00"
    }
}
