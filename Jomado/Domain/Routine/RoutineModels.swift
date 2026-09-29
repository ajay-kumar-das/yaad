import Foundation

enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

struct LocalTime: Codable, Hashable, Comparable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        precondition((0...23).contains(hour))
        precondition((0...59).contains(minute))
        self.hour = hour
        self.minute = minute
    }

    init(date: Date, calendar: Calendar = .current) {
        self.init(
            hour: calendar.component(.hour, from: date),
            minute: calendar.component(.minute, from: date)
        )
    }

    var minutesFromMidnight: Int { hour * 60 + minute }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}

enum RoutineSchedule: Codable, Hashable, Sendable {
    case interval(start: LocalTime, end: LocalTime, everyMinutes: Int, weekdays: Set<Weekday>)
    case fixed(times: [LocalTime], weekdays: Set<Weekday>)

    var weekdays: Set<Weekday> {
        switch self {
        case .interval(_, _, _, let weekdays), .fixed(_, let weekdays): weekdays
        }
    }
}

enum RoutineDeliveryMode: String, Codable, CaseIterable, Hashable, Sendable {
    case alarmAndCompanion
    case companionOnly
}

enum NotificationSoundChoice: String, Codable, CaseIterable, Hashable, Sendable {
    case inherit, systemDefault, softChime, brightBell, gentlePop, birdWhisper, silent

    var displayName: String {
        switch self {
        case .inherit: "Use global default"
        case .systemDefault: "System default"
        case .softChime: "Soft chime"
        case .brightBell: "Bright bell"
        case .gentlePop: "Gentle pop"
        case .birdWhisper: "Bird whisper"
        case .silent: "Silent"
        }
    }

    static var globalChoices: [Self] { allCases.filter { $0 != .inherit } }

    var bundledFileName: String? {
        switch self {
        case .softChime: "jomado-soft-chime.wav"
        case .brightBell: "jomado-bright-bell.wav"
        case .gentlePop: "jomado-gentle-pop.wav"
        case .birdWhisper: "jomado-bird-whisper.wav"
        case .inherit, .systemDefault, .silent: nil
        }
    }

    func resolved(
        globalDefaultRaw: String?,
        legacySoundEnabled: Bool
    ) -> Self {
        guard self == .inherit else { return self }

        if let globalDefaultRaw,
           let global = Self(rawValue: globalDefaultRaw),
           global != .inherit {
            return global
        }

        return legacySoundEnabled ? .systemDefault : .silent
    }
}

struct RoutineTemplate: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let type: RoutineType
    let displayName: String
    let symbolName: String
    let accentHex: String
    let defaultCompletionLabel: String
    let supportedScheduleKinds: Set<ScheduleKind>

    enum ScheduleKind: String, Codable, Hashable, Sendable {
        case interval
        case fixedTimes
    }

    static let catalog: [RoutineTemplate] = RoutineType.allCases
        .filter { $0 != .generic }
        .map { type in
            RoutineTemplate(
                id: "template.\(type.rawValue)",
                type: type,
                displayName: type.displayName,
                symbolName: type.symbolName,
                accentHex: type.accentHex,
                defaultCompletionLabel: type.defaultCompletionLabel,
                supportedScheduleKinds: [.interval, .fixedTimes]
            )
        }
}

struct RoutineInstance: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let templateID: String
    var name: String
    var enabled: Bool
    var type: RoutineType
    var symbolName: String
    var accentHex: String
    var schedule: RoutineSchedule
    var deliveryMode: RoutineDeliveryMode
    var personality: ReminderPersonality
    var personalityPoolRaw: String? = nil
    var intensity: ReminderIntensity
    var smartSnoozeEnabled: Bool
    var snoozeMinutes: Int
    var maxSnoozes: Int
    var completionLabel: String
    let createdAt: Date
    var updatedAt: Date
    var mascotID: String = CompanionMascot.momo.rawValue
    var notificationSound: NotificationSoundChoice = .inherit
    var goal: String? = nil
    var contentTipEnabled: Bool = true

    var selectedPersonalities: Set<ReminderPersonality> {
        let raw = personalityPoolRaw ?? personality.rawValue
        let values = raw.split(separator: "|").compactMap { ReminderPersonality(rawValue: String($0)) }
        return Set(values.isEmpty ? [personality] : values)
    }

    var selectedMascotIDs: Set<String> {
        let values = mascotID.split(separator: "|").map(String.init).filter { CompanionMascot(rawValue: $0) != nil }
        return Set(values.isEmpty ? [CompanionMascot.momo.rawValue] : values)
    }
}

struct RoutineDraft: Hashable, Sendable {
    var type: RoutineType
    var name: String
    var schedule: RoutineSchedule
    var deliveryMode: RoutineDeliveryMode
    var personality: ReminderPersonality
    var personalityPoolRaw: String? = nil
    var intensity: ReminderIntensity
    var smartSnoozeEnabled: Bool
    var snoozeMinutes: Int
    var maxSnoozes: Int
    var symbolName: String? = nil
    var accentHex: String? = nil
    var completionLabel: String? = nil
    var mascotID: String = CompanionMascot.momo.rawValue
    var notificationSound: NotificationSoundChoice = .inherit
    var goal: String? = nil
    var contentTipEnabled: Bool = true

    var selectedPersonalities: Set<ReminderPersonality> {
        let raw = personalityPoolRaw ?? personality.rawValue
        let values = raw.split(separator: "|").compactMap { ReminderPersonality(rawValue: String($0)) }
        return Set(values.isEmpty ? [personality] : values)
    }

    var selectedMascotIDs: Set<String> {
        let values = mascotID.split(separator: "|").map(String.init).filter { CompanionMascot(rawValue: $0) != nil }
        return Set(values.isEmpty ? [CompanionMascot.momo.rawValue] : values)
    }

    func materialize(id: UUID = UUID(), now: Date = .now) -> RoutineInstance {
        RoutineInstance(
            id: id,
            templateID: "template.\(type.rawValue)",
            name: name,
            enabled: true,
            type: type,
            symbolName: symbolName ?? type.symbolName,
            accentHex: accentHex ?? type.accentHex,
            schedule: schedule,
            deliveryMode: deliveryMode,
            personality: personality,
            personalityPoolRaw: personalityPoolRaw,
            intensity: intensity,
            smartSnoozeEnabled: smartSnoozeEnabled,
            snoozeMinutes: snoozeMinutes,
            maxSnoozes: maxSnoozes,
            completionLabel: completionLabel ?? type.defaultCompletionLabel,
            createdAt: now,
            updatedAt: now,
            mascotID: mascotID,
            notificationSound: notificationSound,
            goal: goal,
            contentTipEnabled: contentTipEnabled
        )
    }
}
