import Foundation
import XCTest
@testable import Jomado

final class RoutineSchedulePlannerTests: XCTestCase {
    func testIntervalScheduleRespectsWindowAndWeekdays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 7, minute: 30))
        )
        let end = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 13))
        )

        let routine = RoutineDraft(
            type: .hydration,
            name: "Hydration",
            schedule: .interval(
                start: LocalTime(hour: 8, minute: 0),
                end: LocalTime(hour: 12, minute: 0),
                everyMinutes: 60,
                weekdays: [.monday]
            ),
            deliveryMode: .companionOnly,
            personality: .playful,
            intensity: .balanced,
            smartSnoozeEnabled: true,
            snoozeMinutes: 10,
            maxSnoozes: 3
        ).materialize()

        let dates = RoutineSchedulePlanner.upcomingDates(
            for: routine,
            from: start,
            through: end,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 5)
        XCTAssertEqual(calendar.component(.hour, from: dates[0]), 8)
        XCTAssertEqual(calendar.component(.hour, from: dates[4]), 12)
    }

    func testIntervalScheduleCanCrossMidnight() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 21, minute: 30))
        )
        let end = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: 2, minute: 30))
        )

        let routine = RoutineDraft(
            type: .sleep,
            name: "Night routine",
            schedule: .interval(
                start: LocalTime(hour: 22, minute: 0),
                end: LocalTime(hour: 2, minute: 0),
                everyMinutes: 60,
                weekdays: [.monday]
            ),
            deliveryMode: .companionOnly,
            personality: .gentle,
            intensity: .soft,
            smartSnoozeEnabled: true,
            snoozeMinutes: 10,
            maxSnoozes: 2
        ).materialize()

        let dates = RoutineSchedulePlanner.upcomingDates(
            for: routine,
            from: start,
            through: end,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 5)
        XCTAssertEqual(dates.map { calendar.component(.hour, from: $0) }, [22, 23, 0, 1, 2])
        XCTAssertEqual(calendar.component(.day, from: dates[2]), 29)
    }

    func testOccurrenceKeyIsStableForSameLocalSlot() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Kolkata"))
        let date = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: 8, minute: 15))
        )
        let routineID = try XCTUnwrap(UUID(uuidString: "A11CE000-0000-4000-8000-000000000009"))

        let first = RoutineSchedulePlanner.occurrenceKey(
            routineID: routineID,
            date: date,
            calendar: calendar
        )
        let second = RoutineSchedulePlanner.occurrenceKey(
            routineID: routineID,
            date: date,
            calendar: calendar
        )

        XCTAssertEqual(first, second)
        XCTAssertTrue(first.contains("2026-09-29T08:15"))
        XCTAssertTrue(first.contains("Asia/Kolkata"))
    }
}
