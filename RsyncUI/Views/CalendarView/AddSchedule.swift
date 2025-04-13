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

    @Binding var selectedprofile: String
    @Binding var dateAdded: String
    @Binding var dateRun: String
    @Binding var dateStop: String
    @Binding var istappeddayint: Int

    @State private var schedule: String = ScheduleType.once.rawValue

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    profiles

                    pickerselecttypeoftask
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Run:  ")

                        TextField("Run", text: $dateRun)
                            .frame(width: 130)
                        
                        Button {
                            let date = dateRun.en_us_date_from_string()
                            var datecomponents = DateComponents()
                            datecomponents.hour = date.hourInt + 1
                            datecomponents.day = date.dayInt
                            datecomponents.year = date.yearInt
                            datecomponents.month = date.monthInt
                            let calendar = Calendar.current
                            dateRun = calendar.date(from: datecomponents)?.en_us_string_from_date() ?? ""
                            
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        .buttonBorderShape(.circle)
                        
                        Button {
                            let date = dateRun.en_us_date_from_string()
                            var datecomponents = DateComponents()
                            datecomponents.hour = date.hourInt - 1
                            datecomponents.day = date.dayInt
                            datecomponents.year = date.yearInt
                            datecomponents.month = date.monthInt
                            let calendar = Calendar.current
                            dateRun = calendar.date(from: datecomponents)?.en_us_string_from_date() ?? ""
                        } label: {
                            Image(systemName: "minus")
                                .foregroundColor(.blue)
                        }
                        .buttonBorderShape(.circle)

                        Button("Reset") {
                            dateRun = Date.now.en_us_string_from_date()
                            istappeddayint = 0
                        }
                        
                        Button {
                            do {
                                try scheduledata.validatedate(date: dateRun)
                                try scheduledata.validatedate(date: dateStop)

                                let item = SchedulesConfigurations(profile: selectedprofile,
                                                                   dateAdded: dateAdded,
                                                                   dateRun: dateRun,
                                                                   dateStop: dateStop,
                                                                   schedule: schedule)

                                scheduledata.scheduledata.append(item)

                                // If more than one schedule, sort by dateRun
                                if scheduledata.scheduledata.count > 1 {
                                    scheduledata.scheduledata.sort { item1, item2 in
                                        if let date1 = item1.dateRun?.validate_en_us_date_from_string(),
                                           let date2 = item2.dateRun?.validate_en_us_date_from_string() {
                                            return date1 < date2
                                        }
                                        return false
                                    }
                                }

                                futuredates.scheduledata = scheduledata.scheduledata
                                futuredates.recomputeschedules()

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

                    HStack {
                        Text("Stop: ")

                        TextField("Stop", text: $dateStop)
                            .frame(width: 130)
                        
                        Button("Reset") {
                            var dateComponents = DateComponents()
                            dateComponents.month = 3
                            let futuredateStop = Calendar.current.date(byAdding: dateComponents, to: Date.now)
                            dateStop = futuredateStop?.en_us_string_from_date() ?? Date().en_us_string_from_date()
                        }
                    }
                }
            }
        }
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("", comment: ""),
               selection: $schedule) {
            ForEach(ScheduleType.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var profiles: some View {
        Picker("", selection: $selectedprofile) {
            ForEach(rsyncUIdata.validprofiles) { profile in
                Text(profile.profilename)
                    .tag(profile.profilename)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }
}
