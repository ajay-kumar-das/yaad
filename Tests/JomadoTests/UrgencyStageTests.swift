import XCTest
@testable import Jomado

final class UrgencyStageTests: XCTestCase {
    private let dueDate = Date(timeIntervalSince1970: 10_000)

    func testCanonicalThresholds() {
        XCTAssertEqual(stage(secondsLate: 0), .normal)
        XCTAssertEqual(stage(secondsLate: 179), .normal)
        XCTAssertEqual(stage(secondsLate: 180), .lightOverdue)
        XCTAssertEqual(stage(secondsLate: 599), .lightOverdue)
        XCTAssertEqual(stage(secondsLate: 600), .mediumOverdue)
        XCTAssertEqual(stage(secondsLate: 1_199), .mediumOverdue)
        XCTAssertEqual(stage(secondsLate: 1_200), .redZone)
    }

    func testCompletionOverridesTime() {
        XCTAssertEqual(
            ReminderUrgencyStage.resolve(
                dueDate: dueDate,
                now: dueDate.addingTimeInterval(50_000),
                isCompleted: true
            ),
            .completed
        )
    }

    private func stage(secondsLate: TimeInterval) -> ReminderUrgencyStage {
        ReminderUrgencyStage.resolve(
            dueDate: dueDate,
            now: dueDate.addingTimeInterval(secondsLate)
        )
    }
}

