import Foundation
@preconcurrency import UserNotifications

enum NotificationActionIdentifier {
    static let category = "JOMADO_ROUTINE_REMINDER"
    static let complete = "JOMADO_COMPLETE"
    static let remindLater = "JOMADO_REMIND_LATER"
}

enum NotificationActionKind: String, Sendable {
    case completed
    case remindLater
    case opened
    case dismissed
}

struct NotificationActionEvent: Sendable {
    let action: NotificationActionKind
    let occurrenceID: UUID
    let routineID: UUID
}

actor NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    func registerCategories() {
        let complete = UNNotificationAction(
            identifier: NotificationActionIdentifier.complete,
            title: "Complete",
            options: []
        )
        let remindLater = UNNotificationAction(
            identifier: NotificationActionIdentifier.remindLater,
            title: "Remind me in 10 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: NotificationActionIdentifier.category,
            actions: [complete, remindLater],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "A Jomado routine is ready",
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func schedule(
        occurrence: ReminderOccurrence,
        content item: ReminderContentItem,
        at deliveryDate: Date,
        isFollowUp: Bool = false
    ) async throws {
        let notification = UNMutableNotificationContent()
        notification.title = item.variants.notification.title
        notification.body = item.variants.notification.body
        notification.sound = .default
        notification.categoryIdentifier = NotificationActionIdentifier.category
        notification.threadIdentifier = "routine.\(occurrence.routineID.uuidString)"
        notification.targetContentIdentifier = "occurrence.\(occurrence.id.uuidString)"
        notification.userInfo = [
            "occurrenceID": occurrence.id.uuidString,
            "routineID": occurrence.routineID.uuidString,
            "deepLink": "jomado://occurrence/\(occurrence.id.uuidString)"
        ]

        let interval = max(1, deliveryDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let suffix = isFollowUp ? "follow-up" : "primary"
        let request = UNNotificationRequest(
            identifier: "occurrence.\(occurrence.id.uuidString).\(suffix)",
            content: notification,
            trigger: trigger
        )

        try await center.add(request)
    }

    func cancel(occurrenceID: UUID) {
        let prefix = "occurrence.\(occurrenceID.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [
            "\(prefix).primary",
            "\(prefix).follow-up"
        ])
        center.removeDeliveredNotifications(withIdentifiers: [
            "\(prefix).primary",
            "\(prefix).follow-up"
        ])
    }
}

