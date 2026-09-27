import Foundation

@MainActor
final class NotificationActionRouter {
    static let shared = NotificationActionRouter()

    private var handler: ((NotificationActionEvent) -> Void)?
    private var pendingEvents: [NotificationActionEvent] = []

    private init() {}

    func install(handler: @escaping (NotificationActionEvent) -> Void) {
        self.handler = handler
        let events = pendingEvents
        pendingEvents.removeAll()
        events.forEach(handler)
    }

    func route(_ event: NotificationActionEvent) {
        if let handler {
            handler(event)
        } else {
            pendingEvents.append(event)
        }
    }
}
