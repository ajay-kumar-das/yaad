import Foundation

public enum JomadoExternalActionKind: String, Codable, Hashable, Sendable {
    case alarmStopped
    case opened
}

public enum JomadoExternalEventSource: String, Codable, Hashable, Sendable {
    case alarmKit
}

public struct JomadoExternalEvent: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let routineID: UUID
    public let occurrenceID: UUID
    public let action: JomadoExternalActionKind
    public let source: JomadoExternalEventSource
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        routineID: UUID,
        occurrenceID: UUID,
        action: JomadoExternalActionKind,
        source: JomadoExternalEventSource,
        timestamp: Date = .now
    ) {
        self.id = id
        self.routineID = routineID
        self.occurrenceID = occurrenceID
        self.action = action
        self.source = source
        self.timestamp = timestamp
    }
}

public enum JomadoExternalEventQueue {
    public static let appGroupIdentifier = "group.com.ajaydas.jomado.shared"
    private static let keyPrefix = "jomado.external-event."

    @discardableResult
    public static func enqueue(_ event: JomadoExternalEvent) -> Bool {
        guard
            let defaults = UserDefaults(suiteName: appGroupIdentifier),
            let data = try? JSONEncoder().encode(event)
        else { return false }

        defaults.set(data, forKey: key(for: event.id))
        defaults.synchronize()
        return true
    }

    public static func pendingEvents() -> [JomadoExternalEvent] {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }

        let keys = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .sorted()
        var events: [JomadoExternalEvent] = []

        for key in keys {
            guard
                let data = defaults.data(forKey: key),
                let event = try? JSONDecoder().decode(JomadoExternalEvent.self, from: data)
            else {
                defaults.removeObject(forKey: key)
                continue
            }
            events.append(event)
        }

        return events.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp { return lhs.id.uuidString < rhs.id.uuidString }
            return lhs.timestamp < rhs.timestamp
        }
    }

    public static func acknowledge(eventID: UUID) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        defaults.removeObject(forKey: key(for: eventID))
        defaults.synchronize()
    }

    private static func key(for id: UUID) -> String {
        keyPrefix + id.uuidString
    }
}
