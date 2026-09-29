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
                    guard everyMinutes > 0 else { break }

                    let startMinute = start.minutesFromMidnight
                    let endMinute = end.minutesFromMidnight
                    let finalMinute = endMinute >= startMinute
                        ? endMinute
                        : 24 * 60 + endMinute

                    var minute = startMinute
                    while minute <= finalMinute {
                        let dayOffset = minute / (24 * 60)
                        let minuteOfDay = minute % (24 * 60)
                        guard let occurrenceDay = calendar.date(byAdding: .day, value: dayOffset, to: day) else {
                            break
                        }
                        if let date = date(on: occurrenceDay, minuteOfDay: minuteOfDay, calendar: calendar),
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

    static let earlyActionFraction = 0.10

    static func actionAvailableAt(
        for routine: RoutineInstance,
        occurrenceDate: Date,
        calendar: Calendar = .current
    ) -> Date {
        let interval = nominalIntervalSeconds(
            for: routine,
            around: occurrenceDate,
            calendar: calendar
        )
        return occurrenceDate.addingTimeInterval(-(interval * earlyActionFraction))
    }

    static func canTakeAction(
        for routine: RoutineInstance,
        occurrenceDate: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        now >= actionAvailableAt(
            for: routine,
            occurrenceDate: occurrenceDate,
            calendar: calendar
        )
    }

    private static func nominalIntervalSeconds(
        for routine: RoutineInstance,
        around occurrenceDate: Date,
        calendar: Calendar
    ) -> TimeInterval {
        switch routine.schedule {
        case .interval(_, _, let everyMinutes, _):
            return TimeInterval(max(1, everyMinutes) * 60)

        case .fixed:
            let oneSecondBefore = occurrenceDate.addingTimeInterval(-1)
            let lookback = calendar.date(byAdding: .day, value: -8, to: occurrenceDate)
                ?? occurrenceDate.addingTimeInterval(-8 * 86_400)

            if let previous = upcomingDates(
                for: routine,
                from: lookback,
                through: oneSecondBefore,
                calendar: calendar
            ).last {
                return max(60, occurrenceDate.timeIntervalSince(previous))
            }

            let oneSecondAfter = occurrenceDate.addingTimeInterval(1)
            let lookahead = calendar.date(byAdding: .day, value: 8, to: occurrenceDate)
                ?? occurrenceDate.addingTimeInterval(8 * 86_400)

            if let next = upcomingDates(
                for: routine,
                from: oneSecondAfter,
                through: lookahead,
                calendar: calendar
            ).first {
                return max(60, next.timeIntervalSince(occurrenceDate))
            }

            return 24 * 60 * 60
        }
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
