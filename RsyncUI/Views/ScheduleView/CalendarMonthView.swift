//
//  CalendarMonthView.swift
//  Calendar
//
//  Created by Thomas Evensen on 25/03/2025.
//

import SwiftUI

struct CalendarMonthView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var scheduledata: ObservableScheduleData
    @Bindable var futuredates: ObservableFutureSchedules
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?

    @State private var date = Date.now

    let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    @State private var days: [Date] = []
    @State private var selecteduuids: Set<SchedulesConfigurations.ID> = []
    @State private var dateAdded: String = Date.now.en_string_from_date()
    @State private var dateRun: String = Date.now.en_string_from_date()
    @State private var confirmdelete: Bool = false
    @State private var istappeddayint: Int = 0

    let defaultcolor: Color = .blue
    let globaltimer = GlobalTimer.shared

    var body: some View {
        HStack {
            VStack {
                if date.endOfMonth == Date.now.endOfMonth {
                    Text("\(date.en_string_from_date())")
                        .font(.title)
                        .padding()
                } else {
                    Text("\(Date.fullMonthNames[date.monthInt - 1])")
                        .font(.title)
                        .padding()
                }

                HStack {
                    ForEach(daysOfWeek.indices, id: \.self) { index in
                        Text(daysOfWeek[index])
                            .fontWeight(.black)
                            .foregroundStyle(defaultcolor)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: 450)

                LazyVGrid(columns: columns) {
                    ForEach(days, id: \.self) { day in
                        if day.monthInt != date.monthInt {
                            Text("")
                        } else {
                            if thereisaschedule(day), day >= Date() {
                                CalendarDayView(futuredates: futuredates,
                                                dateRun: $dateRun,
                                                dateAdded: $dateAdded,
                                                istappeddayint: $istappeddayint,
                                                day: day,
                                                style: .thereisaschedule)

                            } else if istappednoschedule(day) {
                                CalendarDayView(futuredates: futuredates,
                                                dateRun: $dateRun,
                                                dateAdded: $dateAdded,
                                                istappeddayint: $istappeddayint,
                                                day: day,
                                                style: .istappednoschedule)
                            } else {
                                CalendarDayView(futuredates: futuredates,
                                                dateRun: $dateRun,
                                                dateAdded: $dateAdded,
                                                istappeddayint: $istappeddayint,
                                                day: day,
                                                style: .normalday)
                            }
                        }
                    }
                }
                .frame(width: 400)

                Spacer()

                if let first = futuredates.firstscheduledate {
                    HStack {
                        Text(first.profile ?? "")
                        Text(first.dateRun ?? "")
                    }
                }
            }

            VStack(alignment: .leading) {
                AddSchedule(rsyncUIdata: rsyncUIdata,
                            scheduledata: scheduledata,
                            futuredates: futuredates,
                            selectedprofileID: $selectedprofileID,
                            dateAdded: $dateAdded,
                            dateRun: $dateRun,
                            istappeddayint: $istappeddayint,
                            date: $date)

                TableofSchedules(selecteduuids: $selecteduuids,
                                 schedules: globaltimer.allSchedules)
                    .confirmationDialog(selecteduuids.count == 1 ? "Delete 1 schedule" :
                        "Delete \(selecteduuids.count) schedules",
                        isPresented: $confirmdelete)
                    {
                        Button("Delete") {
                            scheduledata.delete(selecteduuids)

                            date = Date.now
                            istappeddayint = 0
                            futuredates.lastdateinpresentmont = Date.now.endOfMonth
                             
                            globaltimer.invaldiateallschedulesandtimer()
                            // futuredates.recalculateschedulesGlobalTimer()

                            if globaltimer.allSchedules.isEmpty {
                                futuredates.firstscheduledate = nil
                            } else {
                                futuredates.recomputeschedules()
                            }
                            
                            confirmdelete = false
                            if futuredates.demo == false {
                                /*
                                if let scheduladata = scheduledata.scheduledata {
                                    WriteSchedule(scheduladata)
                                }
                                 */
                            }
                        }
                    }
                    .onDeleteCommand {
                        confirmdelete = true
                    }
            }
        }
        .onAppear {
            days = date.calendarDisplayDays
            if let last = days.last {
                futuredates.lastdateinpresentmont = last.startOfDay
            }
            date = Date.now
            futuredates.lastdateinpresentmont = Date.now.endOfMonth
            if globaltimer.allSchedules.count  > 0 {
                futuredates.recomputeschedules()
            }
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }
        .onChange(of: futuredates.firstscheduledate) {
            if globaltimer.allSchedules.isEmpty {
                globaltimer.invaldiateallschedulesandtimer()
            }
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button {
                    date = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? Date.now
                    futuredates.lastdateinpresentmont = date.endOfMonth
                    futuredates.recomputeschedules()
                    istappeddayint = 0

                } label: {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                }
                .help("Previous month")
            }

            ToolbarItem {
                Button {
                    date = Date.now
                    futuredates.lastdateinpresentmont = Date.now.endOfMonth
                    futuredates.recomputeschedules()
                    istappeddayint = 0
                } label: {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                }
                .help("Today")
            }

            ToolbarItem {
                Button {
                    date = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? Date.now
                    futuredates.lastdateinpresentmont = date.endOfMonth
                    futuredates.recomputeschedules()
                    istappeddayint = 0
                } label: {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                }
                .help("Next month")
            }
        }
    }

    func thereisaschedule(_ date: Date) -> Bool {
        let verifyaschedule = globaltimer.allSchedules.compactMap { schedule in
            schedule.dateRun?.en_date_from_string().startOfDay == date ? true : nil
        }
        return verifyaschedule.count > 0
    }

    func istappednoschedule(_ date: Date) -> Bool {
        date.dayInt == istappeddayint
    }
}
