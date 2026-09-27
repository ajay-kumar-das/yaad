import Foundation

enum RoutineSchedulePlanner {
    static func upcomingDates(
        for routine: RoutineInstance,
        from startDate: Date = .now,
        through endDate: Date,
        calendar baseCalendar: Calendar = .current
    ) -> [Date] {
        guard routine.enabled, endDate > startDate else { return [] }

        let calendar = baseCalendar
        let firstDay = calendar.startOfDay(for: startDate)
        let lastDay = calendar.startOfDay(for: endDate)
        var day = firstDay
        var result: [Date] = []

        while day <= lastDay {
            let weekday = Weekday(rawValue: calendar.component(.weekday, from: day))
            if let weekday, routine.schedule.weekdays.contains(weekday) {
                switch routine.schedule {
                case .interval(let start, let end, let everyMinutes, _):
                    guard everyMinutes > 0, start <= end else { break }
                    var minute = start.minutesFromMidnight
                    while minute <= end.minutesFromMidnight {
                        if let date = date(on: day, minuteOfDay: minute, calendar: calendar),
                           date >= startDate,
                           date <= endDate {
                            result.append(date)
                        }
                        minute += everyMinutes
                    }

                case .fixed(let times, _):
                    for time in Set(times).sorted() {
                        if let date = date(on: day, minuteOfDay: time.minutesFromMidnight, calendar: calendar),
                           date >= startDate,
                           date <= endDate {
                            result.append(date)
                        }
                    }
                }
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }

        return result.sorted()
    }

    static func occurrenceKey(routineID: UUID, date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents(in: calendar.timeZone, from: date)
        return String(
            format: "%@|%04d-%02d-%02dT%02d:%02d|%@",
            routineID.uuidString,
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0,
            parts.hour ?? 0,
            parts.minute ?? 0,
            calendar.timeZone.identifier
        )
    }

    private static func date(on day: Date, minuteOfDay: Int, calendar: Calendar) -> Date? {
        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}
