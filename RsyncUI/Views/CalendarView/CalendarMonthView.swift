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

    @State private var date = Date.now

    let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    @State private var days: [Date] = []
    // @State private var validprofiles: [ProfilesnamesRecord] = []
    @State private var selectedprofile: String = SharedConstants().defaultprofile
    @State private var selecteduuids: Set<SchedulesConfigurations.ID> = []
    @State private var dateAdded: String = Date.now.en_us_string_from_date()
    @State private var dateRun: String = Date.now.en_us_string_from_date()
    @State private var dateStop: String = Date.now.en_us_string_from_date()
    @State private var confirmdelete: Bool = false
    @State private var istappeddayint: Int = 0
    
    let defaultcolor: Color = .blue

    var body: some View {
        HStack {
            VStack {
                if date.endOfMonth == Date.now.endOfMonth {
                    Text("\(date.en_us_string_from_date())")
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
                .frame(width: 400)

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
                    Text(first.en_us_string_from_date())
                }
            }

            VStack(alignment: .leading) {
                AddSchedule(rsyncUIdata: rsyncUIdata,
                            scheduledata: scheduledata,
                            futuredates: futuredates,
                            selectedprofile: $selectedprofile,
                            dateAdded: $dateAdded,
                            dateRun: $dateRun,
                            dateStop: $dateStop,
                            istappeddayint: $istappeddayint)

                TableofSchedules(selecteduuids: $selecteduuids,
                                 schedules: scheduledata.scheduledata)
                    .confirmationDialog(
                        Text("Delete ^[\(selecteduuids.count) schedule](inflect: true)"),
                        isPresented: $confirmdelete
                    ) {
                        Button("Delete") {
                            scheduledata.delete(selecteduuids)
                            futuredates.scheduledata = scheduledata.scheduledata
                            futuredates.recomputeschedules()

                            confirmdelete = false

                            Task {
                                await ActorWriteSchedule(scheduledata.scheduledata)
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
            // Set dateSTop to default three months ahead at 08:00
            dateStop = setstopdate(Date.now).en_us_string_from_date()
            if let last = days.last {
                futuredates.lastdateinpresentmont = last.startOfDay
            }
            date = Date.now
            futuredates.lastdateinpresentmont = Date.now.endOfMonth
            futuredates.recomputeschedules()
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
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
        let verifyaschedule = futuredates.futureschedules.compactMap { schedule in
            schedule.dateRun?.en_us_date_from_string().startOfDay == date ? true : nil
        }
        return verifyaschedule.count > 0
    }

    func istappednoschedule(_ date: Date) -> Bool {
        date.dayInt == istappeddayint
    }

    func setstopdate(_ date: Date) -> Date {
        var datecomponents = DateComponents()
        datecomponents.hour = 8
        datecomponents.day = date.dayInt
        datecomponents.year = date.yearInt
        datecomponents.month = date.monthInt + 3
        let calendar = Calendar.current
        return calendar.date(from: datecomponents) ?? Date()
    }
}
