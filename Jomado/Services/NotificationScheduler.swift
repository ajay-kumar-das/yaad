import Foundation
@preconcurrency import UserNotifications

enum NotificationActionIdentifier {
    static let category = "JOMADO_ROUTINE_REMINDER"
    static let complete = "JOMADO_COMPLETE"
    static let remindLater = "JOMADO_REMIND_LATER"
}

enum NotificationActionKind: String, Codable, Sendable {
    case completed
    case remindLater
    case opened
    case dismissed
    case alarmStopped
}

struct NotificationActionEvent: Codable, Hashable, Sendable {
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
            title: "Remind me later",
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

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func schedule(
        occurrence: ReminderOccurrence,
        content item: ReminderContentItem,
        at deliveryDate: Date,
        isFollowUp: Bool = false,
        soundChoice: NotificationSoundChoice = .inherit
    ) async throws {
        let notification = UNMutableNotificationContent()
        notification.title = item.variants.notification.title
        notification.body = item.variants.notification.body
        notification.sound = notificationSound(for: soundChoice)
        notification.categoryIdentifier = NotificationActionIdentifier.category
        notification.threadIdentifier = "routine.\(occurrence.routineID.uuidString)"
        notification.targetContentIdentifier = "occurrence.\(occurrence.id.uuidString)"
        notification.userInfo = [
            "occurrenceID": occurrence.id.uuidString,
            "routineID": occurrence.routineID.uuidString,
            "deepLink": "jomado://occurrence/\(occurrence.id.uuidString)"
        ]

        let trigger: UNNotificationTrigger
        if deliveryDate.timeIntervalSinceNow <= 60 {
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, deliveryDate.timeIntervalSinceNow),
                repeats: false
            )
        } else {
            var calendar = Calendar.current
            calendar.timeZone = .current
            let components = calendar.dateComponents(
                [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second],
                from: deliveryDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: requestIdentifier(occurrenceID: occurrence.id, isFollowUp: isFollowUp),
            content: notification,
            trigger: trigger
        )

        try await center.add(request)
    }

    private func notificationSound(
        for choice: NotificationSoundChoice
    ) -> UNNotificationSound? {
        let defaults = UserDefaults.standard
        let legacySoundEnabled =
            defaults.object(forKey: "jomado.soundEnabled") as? Bool ?? true
        let resolved = choice.resolved(
            globalDefaultRaw: defaults.string(forKey: "jomado.defaultNotificationSound"),
            legacySoundEnabled: legacySoundEnabled
        )

        switch resolved {
        case .systemDefault, .inherit:
            return .default
        case .silent:
            return nil
        case .softChime, .brightBell, .gentlePop:
            guard
                let fileName = resolved.bundledFileName,
                Bundle.main.url(
                    forResource: (fileName as NSString).deletingPathExtension,
                    withExtension: (fileName as NSString).pathExtension
                ) != nil
            else {
                return .default
            }

            return UNNotificationSound(
                named: UNNotificationSoundName(rawValue: fileName)
            )
        }
    }

    func pendingRequestIdentifiers() async -> Set<String> {
        Set(await center.pendingNotificationRequests().map(\.identifier))
    }

    func cancel(requestIdentifiers: [String]) {
        guard !requestIdentifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: requestIdentifiers)
    }

    func clear(requestIdentifiers: [String]) {
        guard !requestIdentifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: requestIdentifiers)
        center.removeDeliveredNotifications(withIdentifiers: requestIdentifiers)
    }

    func cancel(occurrenceID: UUID) {
        cancel(requestIdentifiers: [
            requestIdentifier(occurrenceID: occurrenceID, isFollowUp: false),
            requestIdentifier(occurrenceID: occurrenceID, isFollowUp: true)
        ])
    }

    func clear(occurrenceID: UUID) {
        clear(requestIdentifiers: [
            requestIdentifier(occurrenceID: occurrenceID, isFollowUp: false),
            requestIdentifier(occurrenceID: occurrenceID, isFollowUp: true)
        ])
    }

    nonisolated func requestIdentifier(occurrenceID: UUID, isFollowUp: Bool) -> String {
        let suffix = isFollowUp ? "follow-up" : "primary"
        return "occurrence.\(occurrenceID.uuidString).\(suffix)"
    }
}
