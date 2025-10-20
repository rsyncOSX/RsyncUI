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

    // DEMO
    @State private var schedulesdemo = ObservableSchedulesDEMO()

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                profiles

                pickerselecttypeoftask

                Image(systemName: "figure.run")
                    .font(.title)
                    .imageScale(.small)
                    .foregroundColor(.blue)

                TextField("", text: $dateRunMonth)
                    .frame(width: 100)

                EditValueErrorScheme(50, NSLocalizedString("", comment: ""),
                                     $dateRunHour,
                                     schedules.verifynextschedule(plannednextschedule: dateRunMonth + " " + dateRunHour))
                    .foregroundColor(schedules.verifynextschedule(plannednextschedule: dateRunMonth + " " + dateRunHour) ? Color.white : Color.red)
                /*
                 TextField("", text: $dateRunMonth)
                     .frame(width: 80)

                 TextField("", text: $dateRunHour)
                     .frame(width: 50, alignment: .center)
                 */

                Button {
                    dateRunMonth = Date.now.en_string_month_from_date()
                    dateRunHour = hournow
                    istappeddayint = 0

                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                        .foregroundColor(.blue)
                }
                .buttonBorderShape(.circle)
                .help("Reset to current date")

                Spacer()

                if SharedReference.shared.scheduledemomode == false {
                    Button {
                        // Just concatenate month + minnutes string
                        let run = dateRunMonth + " " + dateRunHour
                        let profile: String? = if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.id == selectedprofileID }) {
                            rsyncUIdata.validprofiles[index].profilename
                        } else { nil }

                        guard schedules.verifynextschedule(plannednextschedule: run) else {
                            Logger.process.warning("AddSchedule: not valid more than 10 minutes to next schedule")
                            return
                        }

                        schedules.appendfutureschedule(profile: profile, dateRun: run, schedule: schedule)

                        date = Date.now
                        istappeddayint = 0
                        schedules.lastdateinpresentmont = Date.now.endOfMonth
                        // Recompute schedules and set first schedule to execute
                        schedules.recomputeschedules()

                        let globaltimer = GlobalTimer.shared
                        let scheduledatamapped = globaltimer.allSchedules.map { item in
                            item.scheduledata
                        }
                        WriteSchedule(scheduledatamapped as! [SchedulesConfigurations])

                    } label: {
                        Label("Add", systemImage: "plus")
                    }

                } else {
                    Button {
                        schedulesdemo.demodatatestschedule()
                    } label: {
                        Label("DEMO", systemImage: "plus")
                    }
                }
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
        Picker(NSLocalizedString("", comment: ""),
               selection: $schedule)
        {
            ForEach(ScheduleType.allCases) { Text($0.description)
                .tag($0)
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
