import Foundation
import SwiftData

@Model
final class RoutineEntity {
    @Attribute(.unique) var id: UUID
    var templateID: String
    var name: String
    var enabled: Bool
    var typeRaw: String
    var symbolName: String
    var accentHex: String
    var scheduleKindRaw: String
    var startMinute: Int?
    var endMinute: Int?
    var intervalMinutes: Int?
    var fixedMinutesJSON: Data?
    var weekdayMask: Int
    var deliveryModeRaw: String
    var personalityRaw: String
    var intensityRaw: String
    var smartSnoozeEnabled: Bool
    var snoozeMinutes: Int
    var maxSnoozes: Int
    var completionLabel: String
    var createdAt: Date
    var updatedAt: Date
    var lastReconciledAt: Date?

    init(instance: RoutineInstance) {
        id = instance.id
        templateID = instance.templateID
        name = instance.name
        enabled = instance.enabled
        typeRaw = instance.type.rawValue
        symbolName = instance.symbolName
        accentHex = instance.accentHex
        deliveryModeRaw = instance.deliveryMode.rawValue
        personalityRaw = instance.personality.rawValue
        intensityRaw = instance.intensity.rawValue
        smartSnoozeEnabled = instance.smartSnoozeEnabled
        snoozeMinutes = instance.snoozeMinutes
        maxSnoozes = instance.maxSnoozes
        completionLabel = instance.completionLabel
        createdAt = instance.createdAt
        updatedAt = instance.updatedAt
        lastReconciledAt = nil

        switch instance.schedule {
        case .interval(let start, let end, let everyMinutes, let weekdays):
            scheduleKindRaw = RoutineTemplate.ScheduleKind.interval.rawValue
            startMinute = start.minutesFromMidnight
            endMinute = end.minutesFromMidnight
            intervalMinutes = everyMinutes
            fixedMinutesJSON = nil
            weekdayMask = Self.weekdayMask(weekdays)
        case .fixed(let times, let weekdays):
            scheduleKindRaw = RoutineTemplate.ScheduleKind.fixedTimes.rawValue
            startMinute = nil
            endMinute = nil
            intervalMinutes = nil
            fixedMinutesJSON = try? JSONEncoder().encode(times.map(\.minutesFromMidnight))
            weekdayMask = Self.weekdayMask(weekdays)
        }
    }

    var routineType: RoutineType { RoutineType(rawValue: typeRaw) ?? .generic }
    var personality: ReminderPersonality { ReminderPersonality(rawValue: personalityRaw) ?? .playful }
    var intensity: ReminderIntensity { ReminderIntensity(rawValue: intensityRaw) ?? .balanced }
    var deliveryMode: RoutineDeliveryMode { RoutineDeliveryMode(rawValue: deliveryModeRaw) ?? .companionOnly }

    var schedule: RoutineSchedule {
        let weekdays = Self.weekdays(from: weekdayMask)
        if scheduleKindRaw == RoutineTemplate.ScheduleKind.fixedTimes.rawValue {
            let minutes = (try? JSONDecoder().decode([Int].self, from: fixedMinutesJSON ?? Data())) ?? []
            return .fixed(
                times: minutes.map(Self.localTime(from:)),
                weekdays: weekdays
            )
        }

        return .interval(
            start: Self.localTime(from: startMinute ?? 8 * 60),
            end: Self.localTime(from: endMinute ?? 22 * 60),
            everyMinutes: max(1, intervalMinutes ?? 60),
            weekdays: weekdays
        )
    }

    var instance: RoutineInstance {
        RoutineInstance(
            id: id,
            templateID: templateID,
            name: name,
            enabled: enabled,
            type: routineType,
            symbolName: symbolName,
            accentHex: accentHex,
            schedule: schedule,
            deliveryMode: deliveryMode,
            personality: personality,
            intensity: intensity,
            smartSnoozeEnabled: smartSnoozeEnabled,
            snoozeMinutes: snoozeMinutes,
            maxSnoozes: maxSnoozes,
            completionLabel: completionLabel,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private static func localTime(from minutes: Int) -> LocalTime {
        let normalized = min(max(minutes, 0), 23 * 60 + 59)
        return LocalTime(hour: normalized / 60, minute: normalized % 60)
    }

    private static func weekdayMask(_ weekdays: Set<Weekday>) -> Int {
        weekdays.reduce(0) { $0 | (1 << $1.rawValue) }
    }

    private static func weekdays(from mask: Int) -> Set<Weekday> {
        Set(Weekday.allCases.filter { mask & (1 << $0.rawValue) != 0 })
    }
}

@Model
final class ReminderOccurrenceEntity {
    @Attribute(.unique) var id: UUID
    var routineID: UUID
    @Attribute(.unique) var occurrenceKey: String
    var scheduledAt: Date
    var statusRaw: String
    var snoozeCount: Int
    var followUpDate: Date?
    var completedAt: Date?
    var resolvedAt: Date?
    var contentID: String?
    var followUpContentID: String?
    var notificationID: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        routineID: UUID,
        occurrenceKey: String,
        scheduledAt: Date,
        status: ReminderStatus = .scheduled,
        contentID: String? = nil,
        notificationID: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.routineID = routineID
        self.occurrenceKey = occurrenceKey
        self.scheduledAt = scheduledAt
        statusRaw = status.rawValue
        snoozeCount = 0
        followUpDate = nil
        completedAt = nil
        resolvedAt = nil
        self.contentID = contentID
        followUpContentID = nil
        self.notificationID = notificationID
        self.createdAt = createdAt
    }

    var status: ReminderStatus {
        get { ReminderStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    func domainOccurrence(for routine: RoutineEntity) -> ReminderOccurrence {
        ReminderOccurrence(
            id: id,
            routineID: routineID,
            routineType: routine.routineType,
            routineName: routine.name,
            completionLabel: routine.completionLabel,
            dueDate: scheduledAt,
            status: status,
            snoozeCount: snoozeCount,
            followUpDate: followUpDate,
            completedAt: completedAt,
            resolvedAt: resolvedAt
        )
    }

    func apply(_ occurrence: ReminderOccurrence) {
        status = occurrence.status
        snoozeCount = occurrence.snoozeCount
        followUpDate = occurrence.followUpDate
        completedAt = occurrence.completedAt
        resolvedAt = occurrence.resolvedAt
    }
}


@Model
final class ContentExposureEntity {
    var id: UUID
    var contentID: String
    var occurrenceID: UUID
    var semanticFamily: String
    var expressionRaw: String
    var animationCueRaw: String
    var shownAt: Date

    init(
        id: UUID = UUID(),
        contentID: String,
        occurrenceID: UUID,
        semanticFamily: String,
        expression: MascotExpression,
        animationCue: MascotAnimationCue,
        shownAt: Date
    ) {
        self.id = id
        self.contentID = contentID
        self.occurrenceID = occurrenceID
        self.semanticFamily = semanticFamily
        expressionRaw = expression.rawValue
        animationCueRaw = animationCue.rawValue
        self.shownAt = shownAt
    }

    var exposure: ContentExposure {
        ContentExposure(
            contentID: contentID,
            semanticFamily: semanticFamily,
            expression: MascotExpression(rawValue: expressionRaw) ?? .idle,
            animationCue: MascotAnimationCue(rawValue: animationCueRaw) ?? .none,
            shownAt: shownAt
        )
    }
}
