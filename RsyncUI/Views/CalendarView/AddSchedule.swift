//
//  AddSchedule.swift
//  Calendar
//
//  Created by Thomas Evensen on 25/03/2025.
//

import SwiftUI

struct AddSchedule: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var scheduledata: ObservableScheduleData
    @Bindable var futuredates: ObservableFutureSchedules

    @Binding var selectedprofile: String
    @Binding var dateAdded: String
    @Binding var dateRun: String
    @Binding var dateStop: String

    @State private var schedule: String = ScheduleType.once.rawValue

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                profiles

                pickerselecttypeoftask

                TextField("Date Run", text: $dateRun)
                    .frame(width: 130)
                TextField("Date Stop", text: $dateStop)
                    .frame(width: 130)

                Button {
                    let item = SchedulesConfigurations(profile: selectedprofile,
                                                       dateAdded: dateAdded,
                                                       dateRun: dateRun,
                                                       dateStop: dateStop,
                                                       schedule: schedule)

                    scheduledata.scheduledata.append(item)

                    // If more than one schedule, sort by dateRun
                    if scheduledata.scheduledata.count > 1 {
                        scheduledata.scheduledata.sort { $0.dateRun?.en_us_date_from_string() ?? Date() < $1.dateRun?.en_us_date_from_string() ?? Date() }
                    }

                    futuredates.scheduledata = scheduledata.scheduledata
                    futuredates.recomputeschedules()

                    Task {
                        await ActorWriteSchedule(scheduledata.scheduledata)
                    }

                } label: {
                    Label("", systemImage: "plus")
                }
            }
        }
        .padding([.bottom, .top], 7)
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
        .frame(width: 150)
    }
}
