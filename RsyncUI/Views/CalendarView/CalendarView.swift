//
//  CalendarView.swift
//  Calendar
//
//  Created by Thomas Evensen on 25/03/2025.
//

import SwiftUI

struct CalendarView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var scheduledata = ObservableScheduleData()
    @State private var futuredates = ObservableFutureSchedules()

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

    let defaultcolor: Color = .blue
    let schedulecolor: Color = .yellow

    var body: some View {
        HStack {
            VStack {
                Text("\(date.en_us_string_from_date())")
                    .font(.title)
                    .padding()

                HStack {
                    ForEach(daysOfWeek.indices, id: \.self) { index in
                        Text(daysOfWeek[index])
                            .fontWeight(.black)
                            .foregroundStyle(defaultcolor)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: columns) {
                    ForEach(days, id: \.self) { day in
                        if day.monthInt != date.monthInt {
                            Text("")
                        } else {
                            if thereisaschedule(day) && day >= Date() {
                                Text(day.formatted(.dateTime.day()))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(
                                        Circle()
                                            .foregroundStyle(
                                                schedulecolor.opacity(0.3)
                                            )
                                    )
                                    .contextMenu {
                                        Button("Select \(day.formatted(.dateTime.day()))") {
                                            date = day
                                            dateRun = day.en_us_string_from_date()
                                            dateAdded = Date.now.en_us_string_from_date()
                                        }
                                    }
                            } else {
                                Text(day.formatted(.dateTime.day()))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(
                                        Circle()
                                            .foregroundStyle(
                                                Date.now.startOfDay == day.startOfDay
                                                    ? .red.opacity(0.3)
                                                    : defaultcolor.opacity(0.3)
                                            )
                                    )
                                    .contextMenu {
                                        Button("Select \(day.formatted(.dateTime.day()))") {
                                            date = day
                                            dateRun = day.en_us_string_from_date()
                                            dateAdded = Date.now.en_us_string_from_date()
                                        }
                                    }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading) {
                AddSchedule(rsyncUIdata: rsyncUIdata,
                            scheduledata: scheduledata,
                            futuredates: futuredates,
                            selectedprofile: $selectedprofile,
                            dateAdded: $dateAdded,
                            dateRun: $dateRun,
                            dateStop: $dateStop)

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
        .padding()
        .onAppear {
            days = date.calendarDisplayDays
            // Set dateSTop to default three months ahead
            var dateComponents = DateComponents()
            dateComponents.month = 3
            let futuredateStop = Calendar.current.date(byAdding: dateComponents, to: Date.now)
            print(Date.now.monthInt)
            print(futuredateStop?.monthInt ?? 0)
            dateStop = futuredateStop?.en_us_string_from_date() ?? Date().en_us_string_from_date()
            

            if let last = days.last {
                futuredates.lastdateinpresentmont = last.startOfDay
            }

            Task {
                if let data = await ActorReadSchedule().readjsonfilecalendar(rsyncUIdata.validprofiles.map(\.profilename)) {
                    scheduledata.scheduledata = data
                }

                futuredates.scheduledata = scheduledata.scheduledata
                futuredates.recomputeschedules()
            }
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }
        .toolbar {
            ToolbarItem {
                Button {
                    date = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? Date.now
                    futuredates.lastdateinpresentmont = date.endOfMonth
                    futuredates.recomputeschedules()

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
}
