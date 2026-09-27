import AppIntents
import Foundation

struct StopJomadoAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop Jomado Alarm"
    static let description = IntentDescription("Acknowledges a Jomado alarm without completing the routine.")
    static let openAppWhenRun = false

    @Parameter(title: "Routine ID")
    var routineID: String

    @Parameter(title: "Occurrence ID")
    var occurrenceID: String

    init(routineID: UUID, occurrenceID: UUID) {
        self.routineID = routineID.uuidString
        self.occurrenceID = occurrenceID.uuidString
    }

    init() {
        routineID = ""
        occurrenceID = ""
    }

    func perform() async throws -> some IntentResult {
        if let routineID = UUID(uuidString: routineID),
           let occurrenceID = UUID(uuidString: occurrenceID) {
            _ = JomadoExternalEventQueue.enqueue(
                JomadoExternalEvent(
                    routineID: routineID,
                    occurrenceID: occurrenceID,
                    action: .alarmStopped,
                    source: .alarmKit
                )
            )
        }
        return .result()
    }
}

struct OpenJomadoAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Open Jomado"
    static let description = IntentDescription("Opens Jomado for the active routine reminder.")
    static let openAppWhenRun = true

    @Parameter(title: "Routine ID")
    var routineID: String

    @Parameter(title: "Occurrence ID")
    var occurrenceID: String

    init(routineID: UUID, occurrenceID: UUID) {
        self.routineID = routineID.uuidString
        self.occurrenceID = occurrenceID.uuidString
    }

    init() {
        routineID = ""
        occurrenceID = ""
    }

    func perform() async throws -> some IntentResult {
        if let routineID = UUID(uuidString: routineID),
           let occurrenceID = UUID(uuidString: occurrenceID) {
            _ = JomadoExternalEventQueue.enqueue(
                JomadoExternalEvent(
                    routineID: routineID,
                    occurrenceID: occurrenceID,
                    action: .opened,
                    source: .alarmKit
                )
            )
        }
        return .result()
    }
}
