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
    @Bindable var scheduledata: ObservableScheduleData
    @Bindable var futuredates: ObservableFutureSchedules

    @Binding var selectedprofileID: ProfilesnamesRecord.ID?
    @Binding var dateAdded: String
    @Binding var dateRun: String
    @Binding var istappeddayint: Int
    @Binding var date: Date

    @State private var schedule: String = ScheduleType.once.rawValue
    @State private var dateRunMonth: String = Date.now.en_string_month_from_date()
    @State private var dateRunHour: String = ""

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
                    .frame(width: 80)

                TextField("", text: $dateRunHour)
                    .frame(width: 50, alignment: .center)

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

                Button {
                    do {
                        // Just concatenate month + minnutes string
                        let run = dateRunMonth + " " + dateRunHour
                        try scheduledata.validatedate(date: run)

                        let profile: String? = if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.id == selectedprofileID }) {
                            rsyncUIdata.validprofiles[index].profilename
                        } else {
                            nil
                        }

                        let item = SchedulesConfigurations(profile: profile,
                                                           dateAdded: dateAdded,
                                                           dateRun: run,
                                                           schedule: schedule)

                        scheduledata.scheduledata.append(item)

                        // If more than one schedule, sort by dateRun
                        if scheduledata.scheduledata.count > 1 {
                            scheduledata.scheduledata.sort { item1, item2 in
                                if let date1 = item1.dateRun?.validate_en_date_from_string(),
                                   let date2 = item2.dateRun?.validate_en_date_from_string()
                                {
                                    return date1 < date2
                                }
                                return false
                            }
                        }

                        date = Date.now
                        futuredates.scheduledata = scheduledata.scheduledata
                        istappeddayint = 0
                        futuredates.lastdateinpresentmont = Date.now.endOfMonth
                        futuredates.recomputeschedules()
                        futuredates.setfirsscheduledate()

                        Task {
                            await ActorWriteSchedule(scheduledata.scheduledata)
                        }

                    } catch let e {
                        Logger.process.info("AddSchedule: some ERROR adding schedule")

                        let error = e
                        SharedReference.shared.errorobject?.alert(error: error)
                    }

                } label: {
                    Label("Add", systemImage: "plus")
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
