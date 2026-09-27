import Foundation

struct ReminderPresentation: Hashable, Sendable {
    let stage: ReminderUrgencyStage
    let content: ReminderContentItem
    let statusText: String

    static func statusText(stage: ReminderUrgencyStage, dueDate: Date, now: Date) -> String {
        if stage == .completed { return "Done" }
        let seconds = max(0, Int(now.timeIntervalSince(dueDate)))
        let minutes = seconds / 60
        return minutes == 0 ? "Due now" : "\(minutes)m late"
    }
}
