import UIKit
@preconcurrency import UserNotifications

final class JomadoAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task {
            await NotificationScheduler.shared.registerCategories()
        }
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        let info = response.notification.request.content.userInfo
        guard
            let occurrenceString = info["occurrenceID"] as? String,
            let occurrenceID = UUID(uuidString: occurrenceString),
            let routineString = info["routineID"] as? String,
            let routineID = UUID(uuidString: routineString)
        else {
            return
        }

        let action: NotificationActionKind
        switch response.actionIdentifier {
        case NotificationActionIdentifier.complete:
            action = .completed
        case NotificationActionIdentifier.remindLater:
            action = .remindLater
        case UNNotificationDismissActionIdentifier:
            action = .dismissed
        default:
            action = .opened
        }

        let event = NotificationActionEvent(
            action: action,
            occurrenceID: occurrenceID,
            routineID: routineID
        )
        Task { @MainActor in
            NotificationActionRouter.shared.route(event)
        }
    }
}
