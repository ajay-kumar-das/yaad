import XCTest
@testable import Jomado

final class ReminderStateMachineTests: XCTestCase {
    func testDismissalNeverCompletesOccurrence() throws {
        let occurrence = makeOccurrence(status: .alarming)

        let updated = try ReminderStateMachine.apply(.dismissed, to: occurrence)

        XCTAssertEqual(updated.status, .acknowledged)
        XCTAssertNil(updated.completedAt)
        XCTAssertFalse(updated.status.isTerminal)
    }

    func testAlarmStopNeverCompletesOccurrence() throws {
        let occurrence = makeOccurrence(status: .alarming)

        let updated = try ReminderStateMachine.apply(.alarmStopped, to: occurrence)

        XCTAssertEqual(updated.status, .acknowledged)
        XCTAssertNil(updated.completedAt)
    }

    func testSnoozeRemainsUnresolvedAndStoresOneFollowUp() throws {
        let occurrence = makeOccurrence(status: .alarming)
        let followUp = Date(timeIntervalSince1970: 2_000)

        let updated = try ReminderStateMachine.apply(.snoozed(until: followUp), to: occurrence)

        XCTAssertEqual(updated.status, .acknowledged)
        XCTAssertEqual(updated.followUpDate, followUp)
        XCTAssertEqual(updated.snoozeCount, 1)
        XCTAssertFalse(updated.status.isTerminal)
    }

    func testExplicitCompletionIsTerminal() throws {
        let occurrence = makeOccurrence(status: .overdue)
        let completionDate = Date(timeIntervalSince1970: 3_000)

        let updated = try ReminderStateMachine.apply(
            .completed,
            to: occurrence,
            at: completionDate
        )

        XCTAssertEqual(updated.status, .completed)
        XCTAssertEqual(updated.completedAt, completionDate)
        XCTAssertEqual(updated.resolvedAt, completionDate)
        XCTAssertNil(updated.followUpDate)
    }

    func testTerminalOccurrenceRejectsLaterMutation() {
        let occurrence = makeOccurrence(status: .completed)

        XCTAssertThrowsError(try ReminderStateMachine.apply(.dismissed, to: occurrence)) { error in
            XCTAssertEqual(error as? ReminderTransitionError, .terminalState(.completed))
        }
    }

    private func makeOccurrence(status: ReminderStatus) -> ReminderOccurrence {
        ReminderOccurrence(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            routineID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            routineType: .hydration,
            routineName: "Drink water",
            completionLabel: "I drank water",
            dueDate: Date(timeIntervalSince1970: 1_000),
            status: status,
            snoozeCount: 0,
            followUpDate: nil,
            completedAt: status == .completed ? Date(timeIntervalSince1970: 1_500) : nil,
            resolvedAt: status.isTerminal ? Date(timeIntervalSince1970: 1_500) : nil
        )
    }
}

