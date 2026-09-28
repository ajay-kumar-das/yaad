import XCTest
@testable import Jomado

final class NotificationSoundChoiceTests: XCTestCase {
    func testRoutineOverrideWinsOverGlobalDefault() {
        XCTAssertEqual(
            NotificationSoundChoice.brightBell.resolved(
                globalDefaultRaw: NotificationSoundChoice.softChime.rawValue,
                legacySoundEnabled: false
            ),
            .brightBell
        )
    }

    func testInheritedSoundUsesGlobalDefault() {
        XCTAssertEqual(
            NotificationSoundChoice.inherit.resolved(
                globalDefaultRaw: NotificationSoundChoice.gentlePop.rawValue,
                legacySoundEnabled: false
            ),
            .gentlePop
        )
    }

    func testInheritedSoundFallsBackToLegacyEnabledState() {
        XCTAssertEqual(
            NotificationSoundChoice.inherit.resolved(globalDefaultRaw: nil, legacySoundEnabled: true),
            .systemDefault
        )
        XCTAssertEqual(
            NotificationSoundChoice.inherit.resolved(globalDefaultRaw: "invalid", legacySoundEnabled: false),
            .silent
        )
    }
