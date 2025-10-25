//
//  CalendarMonthView.swift
//  Calendar
//
//  Created by Thomas Evensen on 25/03/2025.
//

import SwiftUI

struct CalendarMonthView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var schedules: ObservableSchedules
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?
    @Binding var activeSheet: SheetType?

    @State private var date = Date.now

    let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    @State private var days: [Date] = []
    @State private var selecteduuids: Set<SchedulesConfigurations.ID> = []
    @State private var selecteduuidsnotexecuted: Set<SchedulesConfigurations.ID> = []
    @State private var dateAdded: String = Date.now.en_string_from_date()
    @State private var dateRun: String = Date.now.en_string_from_date()
    @State private var confirmdelete: Bool = false
    @State private var confirmdeletenotexecuted: Bool = false
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
                                CalendarDayView(dateRun: $dateRun,
                                                dateAdded: $dateAdded,
                                                istappeddayint: $istappeddayint,
                                                day: day,
                                                style: .thereisaschedule)

                            } else if istappednoschedule(day) {
                                CalendarDayView(dateRun: $dateRun,
                                                dateAdded: $dateAdded,
                                                istappeddayint: $istappeddayint,
                                                day: day,
                                                style: .istappednoschedule)
                            } else {
                                CalendarDayView(dateRun: $dateRun,
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

                if let first = globaltimer.firstscheduledate, globaltimer.timerIsActive() {
                    HStack {
                        Text(first.profile ?? "")
                        Text(first.dateRun ?? "")
                    }
                }
            }

            VStack(alignment: .leading) {
                AddSchedule(rsyncUIdata: rsyncUIdata,
                            schedules: schedules,
                            selectedprofileID: $selectedprofileID,
                            dateAdded: $dateAdded,
                            dateRun: $dateRun,
                            istappeddayint: $istappeddayint,
                            date: $date)

                VStack {
                    TableofSchedules(selecteduuids: $selecteduuids)
                        .confirmationDialog(selecteduuids.count == 1 ? "Delete 1 schedule" :
                            "Delete \(selecteduuids.count) schedules",
                            isPresented: $confirmdelete)
                        {
                            Button("Delete") {
                                schedules.delete(selecteduuids)

                                date = Date.now
                                istappeddayint = 0
                                schedules.lastdateinpresentmont = Date.now.endOfMonth

                                if globaltimer.allSchedules.isEmpty {
                                    globaltimer.firstscheduledate = nil
                                } else {
                                    schedules.recomputeschedules()
                                }

                                confirmdelete = false

                                let scheduledatamapped = globaltimer.allSchedules.map { item in
                                    item.scheduledata
                                }
                                WriteSchedule(scheduledatamapped as! [SchedulesConfigurations])

                                /* DEMO SCHEDULE
                                 if SharedReference.shared.scheduledemomode == false {
                                     let scheduledatamapped = globaltimer.allSchedules.map { item in
                                         item.scheduledata
                                     }
                                     WriteSchedule(scheduledatamapped as! [SchedulesConfigurations])
                                 }
                                  */
                            }
                        }
                        .onDeleteCommand {
                            confirmdelete = true
                        }

                    if GlobalTimer.shared.notExecutedSchedulesafterWakeUp.count > 0 {
                        HStack {
                            /*
                             Button("Move to Not Executed ↓") {
                                 GlobalTimer.shared.moveToNotExecuted(itemIDs: Array(selecteduuids))
                                 selecteduuids.removeAll()
                             }
                             .disabled(selecteduuids.isEmpty)
                              */

                            Button("Move to Schedules ↑") {
                                GlobalTimer.shared.moveToSchedules(itemIDs: Array(selecteduuidsnotexecuted))
                                selecteduuidsnotexecuted.removeAll()
                            }
                            .disabled(selecteduuidsnotexecuted.isEmpty)
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()

                        TableofNotExeSchedules(selecteduuids: $selecteduuidsnotexecuted)
                            .confirmationDialog(selecteduuidsnotexecuted.count == 1 ? "Delete 1 schedule" :
                                "Delete \(selecteduuidsnotexecuted.count) schedules",
                                isPresented: $confirmdeletenotexecuted)
                            {
                                Button("Delete") {
                                    schedules.deletenotexecuted(selecteduuidsnotexecuted)
                                }
                            }
                            .onDeleteCommand {
                                confirmdeletenotexecuted = true
                            }
                    }
                }
            }
        }
        .onAppear {
            days = date.calendarDisplayDays
            if let last = days.last {
                schedules.lastdateinpresentmont = last.startOfDay
            }
            date = Date.now
            schedules.lastdateinpresentmont = Date.now.endOfMonth
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }
        .onChange(of: globaltimer.firstscheduledate) {
            if globaltimer.allSchedules.isEmpty {
                globaltimer.invalidateAllSchedulesAndTimer()
            }
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button {
                    date = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? Date.now
                    schedules.lastdateinpresentmont = date.endOfMonth
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
                    schedules.lastdateinpresentmont = Date.now.endOfMonth
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
                    schedules.lastdateinpresentmont = date.endOfMonth
                    istappeddayint = 0
                } label: {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                }
                .help("Next month")
            }

            ToolbarItem {
                Spacer()
            }

            if #available(macOS 26.0, *) {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .close) {
                        activeSheet = nil
                        dismiss()
                    }
                    .glassEffect()
                }
            } else {
                ToolbarItem {
                    Button {
                        activeSheet = nil
                    } label: {
                        Image(systemName: "return")
                    }
                    .help("Close")
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    func thereisaschedule(_ date: Date) -> Bool {
        let verifyaschedule = globaltimer.allSchedules.compactMap { schedule in
            schedule.scheduledata?.dateRun?.en_date_from_string().startOfDay == date ? true : nil
        }
        return verifyaschedule.count > 0
    }

    func istappednoschedule(_ date: Date) -> Bool {
        date.dayInt == istappeddayint
    }
}
