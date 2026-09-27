import AppIntents
import Foundation

struct StopJomadoAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Jomado Alarm"
    static var description = IntentDescription("Acknowledges a Jomado alarm without completing the routine.")
    static var openAppWhenRun = false

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
    static var title: LocalizedStringResource = "Open Jomado"
    static var description = IntentDescription("Opens Jomado for the active routine reminder.")
    static var openAppWhenRun = true

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
