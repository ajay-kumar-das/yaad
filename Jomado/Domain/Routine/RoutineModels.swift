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

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}

enum RoutineSchedule: Codable, Hashable, Sendable {
    case interval(start: LocalTime, end: LocalTime, everyMinutes: Int, weekdays: Set<Weekday>)
    case fixed(times: [LocalTime], weekdays: Set<Weekday>)
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
    var personality: ReminderPersonality
    var intensity: ReminderIntensity
    var smartSnoozeEnabled: Bool
    var completionLabel: String
    let createdAt: Date
    var updatedAt: Date
}

