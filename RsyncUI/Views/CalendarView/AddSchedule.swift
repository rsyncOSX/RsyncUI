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

    @State private var schedule: String = ScheduleType.once.rawValue

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack (alignment: .leading) {
                    profiles

                    pickerselecttypeoftask
                }
                

                VStack (alignment: .trailing) {
                    HStack {
                        
                        Text("Date run: ")
                        
                        TextField("Date run", text: $dateRun)
                            .frame(width: 130)
                    }
                    
                    HStack {
                        Text("Date stop: ")
                        
                        TextField("Date stop", text: $dateStop)
                            .frame(width: 130)
                    }
                    
                }
                
                Spacer()

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
                    Label("", systemImage: "plus")
                }
                .buttonStyle(ColorfulButtonStyle())
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
        .frame(width: 150)
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
