import Foundation

enum ReminderStatus: String, Codable, Hashable, Sendable {
    case scheduled
    case alarming
    case acknowledged
    case overdue
    case actionStarted
    case completed
    case skipped
    case expired

    var isTerminal: Bool {
        self == .completed || self == .skipped || self == .expired
    }
}

enum ReminderEvent: Hashable, Sendable {
    case delivered
    case opened
    case dismissed
    case alarmStopped
    case snoozed(until: Date)
    case timeAdvanced
    case completed
    case skipped
    case expired
}

struct ReminderOccurrence: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let routineID: UUID
    let routineType: RoutineType
    let routineName: String
    let completionLabel: String
    let dueDate: Date
    var status: ReminderStatus
    var snoozeCount: Int
    var followUpDate: Date?
    var completedAt: Date?
    var resolvedAt: Date?
}

enum ReminderTransitionError: Error, Equatable {
    case terminalState(ReminderStatus)
}

enum ReminderStateMachine {
    static func apply(
        _ event: ReminderEvent,
        to occurrence: ReminderOccurrence,
        at date: Date = .now
    ) throws -> ReminderOccurrence {
        if occurrence.status.isTerminal {
            throw ReminderTransitionError.terminalState(occurrence.status)
        }

        var updated = occurrence

        switch event {
        case .delivered:
            updated.status = .alarming
        case .opened:
            updated.status = .actionStarted
        case .dismissed, .alarmStopped:
            updated.status = .acknowledged
        case .snoozed(let followUp):
            updated.status = .acknowledged
            updated.snoozeCount += 1
            updated.followUpDate = followUp
        case .timeAdvanced:
            if date >= occurrence.dueDate {
                updated.status = .overdue
            }
        case .completed:
            updated.status = .completed
            updated.completedAt = date
            updated.resolvedAt = date
            updated.followUpDate = nil
        case .skipped:
            updated.status = .skipped
            updated.resolvedAt = date
            updated.followUpDate = nil
        case .expired:
            updated.status = .expired
            updated.resolvedAt = date
            updated.followUpDate = nil
        }

        return updated
    }
}

