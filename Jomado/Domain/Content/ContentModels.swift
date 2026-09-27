import Foundation

struct ContentPack: Codable, Hashable, Sendable {
    let schemaVersion: Int
    let pack: ContentPackMetadata
    let items: [ReminderContentItem]
}

struct ContentPackMetadata: Codable, Hashable, Sendable {
    enum Source: String, Codable, Sendable {
        case bundled
        case downloaded
    }

    let id: String
    let version: Int
    let locale: String
    let minimumAppVersion: String
    let source: Source
    let generatedAt: Date
}

struct ReminderContentItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let routineType: RoutineType
    let stage: ReminderUrgencyStage
    let personality: ReminderPersonality
    let intensity: ReminderIntensity
    let locale: String
    let variants: ContentVariants
    let mascot: MascotDirection
    let tags: [String]
    let dayparts: [ContentDaypart]
    let cooldownMinutes: Int
    let semanticFamily: String
    let priority: Int
    let enabled: Bool
    let safety: ContentSafetyReview
}

struct ContentVariants: Codable, Hashable, Sendable {
    let notification: NotificationCopy
    let liveActivity: LiveActivityCopy
    let inApp: InAppCopy
}

struct NotificationCopy: Codable, Hashable, Sendable {
    let title: String
    let body: String
}

struct LiveActivityCopy: Codable, Hashable, Sendable {
    let headline: String
    let body: String
    let compactStatus: String
}

struct InAppCopy: Codable, Hashable, Sendable {
    let eyebrow: String
    let headline: String
    let body: String
    let tip: String?
    let completionLabel: String
}

struct MascotDirection: Codable, Hashable, Sendable {
    let character: String
    let expression: MascotExpression
    let pose: String
    let prop: String?
    let animationCue: MascotAnimationCue
    let accessibilityLabel: String
}

enum ContentDaypart: String, Codable, CaseIterable, Hashable, Sendable {
    case any
    case morning
    case afternoon
    case evening
    case night

    static func resolve(for date: Date, calendar: Calendar = .current) -> Self {
        switch calendar.component(.hour, from: date) {
        case 5..<12: .morning
        case 12..<17: .afternoon
        case 17..<22: .evening
        default: .night
        }
    }
}

struct ContentSafetyReview: Codable, Hashable, Sendable {
    let medicalClaimReviewed: Bool
    let ageSafe: Bool
    let reviewer: String
    let reviewedAt: String
}

struct ContentExposure: Codable, Hashable, Sendable {
    let contentID: String
    let semanticFamily: String
    let expression: MascotExpression
    let animationCue: MascotAnimationCue
    let shownAt: Date
}

extension ReminderContentItem {
    static var safeFallback: ReminderContentItem {
        safeFallback(for: .normal)
    }

    static func safeFallback(
        for stage: ReminderUrgencyStage,
        routineType: RoutineType = .generic
    ) -> ReminderContentItem {
        let copy: (
            notificationTitle: String,
            notificationBody: String,
            headline: String,
            body: String,
            compactStatus: String,
            eyebrow: String,
            inAppHeadline: String,
            inAppBody: String,
            expression: MascotExpression,
            cue: MascotAnimationCue
        ) = switch stage {
        case .normal:
            (
                "Your Jomado reminder",
                "Your next small routine is ready.",
                "ROUTINE READY",
                "One small step is waiting for you.",
                "Due now",
                "A SMALL STEP",
                "Your routine is ready",
                "Complete it when you are ready, or choose a clear alternative below.",
                .hopeful,
                .gentleBounce
            )
        case .lightOverdue:
            (
                "A routine is still waiting",
                "This reminder is a few minutes late.",
                "STILL WAITING",
                "This routine is a little late.",
                "3m late",
                "A LITTLE LATE",
                "This routine is still waiting",
                "Complete it, snooze it, or skip it clearly. It remains unresolved until then.",
                .pouty,
                .pout
            )
        case .mediumOverdue:
            (
                "Routine overdue",
                "This Jomado reminder is still unresolved.",
                "ROUTINE OVERDUE",
                "Complete or skip this routine.",
                "10m late",
                "STILL UNRESOLVED",
                "Your routine is overdue",
                "Use an explicit action below so Jomado records the right outcome.",
                .concerned,
                .concernedPulse
            )
        case .redZone:
            (
                "Routine needs attention",
                "Complete or skip this unresolved reminder.",
                "NEEDS ATTENTION",
                "Complete or skip this routine.",
                "20m late",
                "NEEDS ATTENTION",
                "Choose the outcome clearly",
                "This reminder is still unresolved. Complete it, snooze it, or skip it.",
                .urgent,
                .dramaticWobble
            )
        case .completed:
            (
                "Nice work!",
                "Your Jomado routine is complete.",
                "GREAT JOB!",
                "You completed this routine.",
                "Done",
                "SMALL WIN",
                "You did it!",
                "Your routine is complete. Momo is proud of this small win.",
                .celebrating,
                .celebrate
            )
        }

        return ReminderContentItem(
            id: "\(routineType.rawValue).playful.\(stage.rawValue).safe-fallback.001",
            routineType: routineType,
            stage: stage,
            personality: .playful,
            intensity: .balanced,
            locale: "en",
            variants: ContentVariants(
                notification: NotificationCopy(
                    title: copy.notificationTitle,
                    body: copy.notificationBody
                ),
                liveActivity: LiveActivityCopy(
                    headline: copy.headline,
                    body: copy.body,
                    compactStatus: copy.compactStatus
                ),
                inApp: InAppCopy(
                    eyebrow: copy.eyebrow,
                    headline: copy.inAppHeadline,
                    body: copy.inAppBody,
                    tip: nil,
                    completionLabel: routineType.defaultCompletionLabel
                )
            ),
            mascot: MascotDirection(
                character: "momo",
                expression: copy.expression,
                pose: copy.expression.rawValue,
                prop: nil,
                animationCue: copy.cue,
                accessibilityLabel: copy.expression.accessibilityDescription
            ),
            tags: ["fallback"],
            dayparts: [.any],
            cooldownMinutes: 0,
            semanticFamily: "safe-fallback",
            priority: -100,
            enabled: true,
            safety: ContentSafetyReview(
                medicalClaimReviewed: true,
                ageSafe: true,
                reviewer: "product",
                reviewedAt: "2026-09-27"
            )
        )
    }
}
