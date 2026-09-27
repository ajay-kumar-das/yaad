import XCTest
@testable import Jomado

final class ContentEngineTests: XCTestCase {
    func testValidatorRejectsOverlongNotificationTitle() {
        let item = makeItem(
            id: "hydration.playful.normal.long-title.001",
            title: String(repeating: "x", count: 33)
        )
        let pack = makePack(items: [item])

        XCTAssertThrowsError(try ContentValidator.validate(pack)) { error in
            XCTAssertEqual(
                error as? ContentValidationError,
                .fieldTooLong(
                    itemID: item.id,
                    field: "notification.title",
                    limit: 32
                )
            )
        }
    }

    func testValidatorRejectsDuplicateIDs() {
        let item = makeItem(id: "hydration.playful.normal.duplicate.001")
        let pack = makePack(items: [item, item])

        XCTAssertThrowsError(try ContentValidator.validate(pack)) { error in
            XCTAssertEqual(error as? ContentValidationError, .duplicateID(item.id))
        }
    }

    func testSelectorAvoidsItemInsideCooldownWhenAlternativeExists() {
        let first = makeItem(id: "hydration.playful.normal.first.001", priority: 50)
        let second = makeItem(id: "hydration.playful.normal.second.001", priority: 10)
        let now = Date(timeIntervalSince1970: 100_000)
        let exposure = ContentExposure(
            contentID: first.id,
            semanticFamily: first.semanticFamily,
            expression: first.mascot.expression,
            animationCue: first.mascot.animationCue,
            shownAt: now.addingTimeInterval(-60)
        )

        let selection = ContentSelector.select(
            from: [first, second],
            context: context(date: now),
            exposures: [exposure]
        )

        XCTAssertEqual(selection?.id, second.id)
    }

    func testSelectorIsReproducibleForSameContext() {
        let items = [
            makeItem(id: "hydration.playful.normal.first.001"),
            makeItem(id: "hydration.playful.normal.second.001"),
            makeItem(id: "hydration.playful.normal.third.001")
        ]
        let context = context(date: Date(timeIntervalSince1970: 100_000))

        let first = ContentSelector.select(from: items, context: context, exposures: [])
        let second = ContentSelector.select(from: items, context: context, exposures: [])

        XCTAssertEqual(first?.id, second?.id)
    }

    private func context(date: Date) -> ContentSelectionContext {
        ContentSelectionContext(
            routineID: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            routineType: .hydration,
            stage: .normal,
            personality: .playful,
            intensity: .balanced,
            locale: "en",
            occurrenceSlot: "morning-1",
            date: date
        )
    }

    private func makePack(items: [ReminderContentItem]) -> ContentPack {
        ContentPack(
            schemaVersion: 1,
            pack: ContentPackMetadata(
                id: "test-pack",
                version: 1,
                locale: "en",
                minimumAppVersion: "0.1.0",
                source: .bundled,
                generatedAt: Date(timeIntervalSince1970: 0)
            ),
            items: items
        )
    }

    private func makeItem(
        id: String,
        title: String = "Water time",
        priority: Int = 0
    ) -> ReminderContentItem {
        ReminderContentItem(
            id: id,
            routineType: .hydration,
            stage: .normal,
            personality: .playful,
            intensity: .balanced,
            locale: "en",
            variants: ContentVariants(
                notification: NotificationCopy(title: title, body: "Take a water break."),
                liveActivity: LiveActivityCopy(
                    headline: "WATER TIME",
                    body: "A few sips moves this forward.",
                    compactStatus: "Due now"
                ),
                inApp: InAppCopy(
                    eyebrow: "YOUR WATER BREAK",
                    headline: "A tiny mission",
                    body: "A few comfortable sips is enough.",
                    tip: nil,
                    completionLabel: "I drank water"
                )
            ),
            mascot: MascotDirection(
                character: "momo",
                expression: .hopeful,
                pose: "wave",
                prop: "waterBottle",
                animationCue: .gentleBounce,
                accessibilityLabel: "Momo waves with a hopeful smile"
            ),
            tags: ["test"],
            dayparts: [.any],
            cooldownMinutes: 240,
            semanticFamily: id,
            priority: priority,
            enabled: true,
            safety: ContentSafetyReview(
                medicalClaimReviewed: true,
                ageSafe: true,
                reviewer: "tests",
                reviewedAt: "2026-09-27"
            )
        )
    }
}
