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
            CalendarMonthGridView(date: $date,
                                  daysOfWeek: daysOfWeek,
                                  columns: columns,
                                  days: days,
                                  dateRun: $dateRun,
                                  dateAdded: $dateAdded,
                                  istappeddayint: $istappeddayint,
                                  defaultcolor: defaultcolor,
                                  thereIsASchedule: thereIsASchedule,
                                  isTappedNoSchedule: isTappedNoSchedule,
                                  firstScheduledText: firstScheduledText)

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
                            isPresented: $confirmdelete) {
                                Button("Delete") {
                                    schedules.delete(selecteduuids)

                                    date = Date.now
                                    istappeddayint = 0
                                    schedules.lastdateinnextmonth = Date.now.endOfCurrentMonth

                                    confirmdelete = false

                                    let scheduledatamapped = globaltimer.allSchedules.map { item in
                                        item.scheduledata
                                    }

                                    if let scheduledatamapped = scheduledatamapped as? [SchedulesConfigurations] {
                                        Task { @MainActor in
                                            await WriteSchedule.write(scheduledatamapped)
                                        }
                                    }

                                    if globaltimer.allSchedules.isEmpty {
                                        globaltimer.firstscheduledate = nil
                                    } else {
                                        globaltimer.setfirsscheduledate()
                                    }
                                }
                        }
                        .onDeleteCommand {
                            confirmdelete = true
                        }

                    if GlobalTimer.shared.notExecutedSchedulesafterWakeUp.count > 0 {
                        ConditionalGlassButton(
                            systemImage: "",
                            text: "Move to Schedules ↑",
                            helpText: "Move to Schedules"
                        ) {
                            GlobalTimer.shared.moveToSchedules(itemIDs: Array(selecteduuidsnotexecuted))
                            selecteduuidsnotexecuted.removeAll()
                        }
                        .disabled(selecteduuidsnotexecuted.isEmpty)
                        .padding()

                        TableofNotExeSchedules(selecteduuids: $selecteduuidsnotexecuted)
                            .confirmationDialog(selecteduuidsnotexecuted.count == 1 ? "Delete 1 schedule" :
                                "Delete \(selecteduuidsnotexecuted.count) schedules",
                                isPresented: $confirmdeletenotexecuted) {
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
            initializeCalendar()
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
        .toolbar { calendartoolbarcontent }
    }

    @ToolbarContentBuilder
    private var calendartoolbarcontent: some ToolbarContent {
        ToolbarItem {
            ConditionalGlassButton(
                systemImage: "arrow.left",
                helpText: "Previous month"
            ) {
                date = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? Date.now
                schedules.lastdateinnextmonth = date.endOfCurrentMonth
                istappeddayint = 0
            }
        }

        ToolbarItem {
            ConditionalGlassButton(
                systemImage: "clock",
                helpText: "Today"
            ) {
                date = Date.now
                schedules.lastdateinnextmonth = Date.now.endOfCurrentMonth
                istappeddayint = 0
            }
        }

        ToolbarItem {
            ConditionalGlassButton(
                systemImage: "arrow.right",
                helpText: "Next month"
            ) {
                date = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? Date.now
                schedules.lastdateinnextmonth = date.endOfCurrentMonth
                istappeddayint = 0
            }
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
                .buttonStyle(RefinedGlassButtonStyle())
            }
        } else {
            ToolbarItem {
                Button {
                    activeSheet = nil
                } label: {
                    Label("Close", systemImage: "return")
                        .labelStyle(.iconOnly)
                }
                .help("Close")
                .buttonStyle(.borderedProminent)
            }
        }
    }

    func thereIsASchedule(_ date: Date) -> Bool {
        let verifyaschedule = globaltimer.allSchedules.compactMap { schedule in
            schedule.scheduledata?.dateRun?.en_date_from_string().startOfDay == date ? true : nil
        }
        return verifyaschedule.count > 0
    }

    func isTappedNoSchedule(_ date: Date) -> Bool {
        date.dayInt == istappeddayint
    }

    var firstScheduledText: String? {
        guard let first = globaltimer.firstscheduledate, globaltimer.timerIsActive() else { return nil }
        let profile = first.profile ?? ""
        let runDate = first.dateRun ?? ""
        return "\(profile) \(runDate)"
    }

    private func initializeCalendar() {
        days = date.calendarDisplayDays
        if let last = days.last {
            schedules.lastdateinnextmonth = last.startOfDay
        }
        date = Date.now
        schedules.lastdateinnextmonth = Date.now.endOfCurrentMonth
    }
}
