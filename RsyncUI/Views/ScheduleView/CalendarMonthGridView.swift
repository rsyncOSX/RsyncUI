import SwiftUI

struct CalendarMonthGridView: View {
    @Binding var date: Date
    let daysOfWeek: [String]
    let columns: [GridItem]
    let days: [Date]
    @Binding var dateRun: String
    @Binding var dateAdded: String
    @Binding var istappeddayint: Int
    let defaultcolor: Color
    let thereIsASchedule: (Date) -> Bool
    let isTappedNoSchedule: (Date) -> Bool
    let firstScheduledText: String?

    var body: some View {
        VStack {
            if date.endOfCurrentMonth == Date.now.endOfCurrentMonth {
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
                        if thereIsASchedule(day), day >= Date() {
                            CalendarDayView(dateRun: $dateRun,
                                            dateAdded: $dateAdded,
                                            istappeddayint: $istappeddayint,
                                            day: day,
                                            style: .thereisaschedule)
                        } else if isTappedNoSchedule(day) {
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

            if let firstScheduledText {
                Text(firstScheduledText)
            }
        }
    }
}
