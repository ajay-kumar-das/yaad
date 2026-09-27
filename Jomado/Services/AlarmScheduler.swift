import AlarmKit
import Foundation
import SwiftUI

struct JomadoAlarmMetadata: AlarmMetadata {
    let routineID: UUID
    let occurrenceID: UUID
    let routineName: String
    let message: String
}

enum JomadoAlarmAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied

    var canSchedule: Bool { self == .authorized }
}

@MainActor
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    private let manager: AlarmManager

    init(manager: AlarmManager = .shared) {
        self.manager = manager
    }

    func authorizationStatus() -> JomadoAlarmAuthorizationStatus {
        switch manager.authorizationState {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    @discardableResult
    func requestAuthorization() async throws -> Bool {
        switch try await manager.requestAuthorization() {
        case .authorized:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    func scheduledAlarmIDs() -> Set<UUID> {
        Set(manager.alarms.map(\.id))
    }

    func schedule(
        occurrence: ReminderOccurrence,
        content: ReminderContentItem,
        at date: Date
    ) async throws {
        let openButton = AlarmButton(
            text: "Open Jomado",
            textColor: .white,
            systemImageName: "arrow.right.circle.fill"
        )
        let title: LocalizedStringResource = "\(content.variants.notification.title)"
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: title,
                secondaryButton: openButton,
                secondaryButtonBehavior: .custom
            )
        )
        let metadata = JomadoAlarmMetadata(
            routineID: occurrence.routineID,
            occurrenceID: occurrence.id,
            routineName: occurrence.routineName,
            message: content.variants.notification.body
        )
        let attributes = AlarmAttributes<JomadoAlarmMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color(jomadoHex: "35C8F6")
        )
        let configuration = AlarmManager.AlarmConfiguration<JomadoAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: StopJomadoAlarmIntent(
                routineID: occurrence.routineID,
                occurrenceID: occurrence.id
            ),
            secondaryIntent: OpenJomadoAlarmIntent(
                routineID: occurrence.routineID,
                occurrenceID: occurrence.id
            ),
            sound: .default
        )

        _ = try await manager.schedule(id: occurrence.id, configuration: configuration)
    }

    func cancel(id: UUID) {
        try? manager.cancel(id: id)
    }

    func cancel(ids: some Sequence<UUID>) {
        for id in ids {
            try? manager.cancel(id: id)
        }
    }
}
