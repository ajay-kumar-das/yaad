import ActivityKit
import Foundation

struct LiveActivityCoordinator: Sendable {
    var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(
        occurrence: ReminderOccurrence,
        presentation: ReminderPresentation,
        mascotID: String
    ) async throws {
        guard activitiesEnabled else { return }

        let state = makeState(occurrence: occurrence, presentation: presentation)
        let content = ActivityContent(
            state: state,
            staleDate: nil,
            relevanceScore: 80
        )

        if let existing = activity(for: occurrence.id) {
            await existing.update(content)
            return
        }

        _ = try Activity<JomadoActivityAttributes>.request(
            attributes: makeAttributes(occurrence: occurrence, mascotID: mascotID),
            content: content,
            pushType: nil
        )
    }

    func schedule(
        occurrence: ReminderOccurrence,
        presentation: ReminderPresentation,
        mascotID: String
    ) throws {
        guard activitiesEnabled else { return }
        guard activity(for: occurrence.id) == nil else { return }

        let state = makeState(occurrence: occurrence, presentation: presentation)
        let content = ActivityContent(
            state: state,
            staleDate: nil,
            relevanceScore: 70
        )
        let alert = AlertConfiguration(
            title: "Jomado reminder",
            body: "Your routine is ready.",
            sound: .default
        )

        _ = try Activity<JomadoActivityAttributes>.request(
            attributes: makeAttributes(occurrence: occurrence, mascotID: mascotID),
            content: content,
            pushType: nil,
            style: .standard,
            alertConfiguration: alert,
            start: occurrence.dueDate
        )
    }

    func update(
        occurrence: ReminderOccurrence,
        presentation: ReminderPresentation
    ) async {
        guard let activity = activity(for: occurrence.id) else { return }

        let state = makeState(occurrence: occurrence, presentation: presentation)
        let content = ActivityContent(
            state: state,
            staleDate: nil,
            relevanceScore: presentation.stage == .redZone ? 100 : 80
        )
        await activity.update(content)
    }

    func end(
        occurrence: ReminderOccurrence,
        presentation: ReminderPresentation,
        immediate: Bool
    ) async {
        guard let activity = activity(for: occurrence.id) else { return }

        let finalState = makeState(occurrence: occurrence, presentation: presentation)
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: nil,
            relevanceScore: 0
        )
        let dismissal: ActivityUIDismissalPolicy = immediate
            ? .immediate
            : .after(.now.addingTimeInterval(600))
        await activity.end(finalContent, dismissalPolicy: dismissal)
    }

    func occurrenceIDs() -> Set<UUID> {
        Set(
            Activity<JomadoActivityAttributes>.activities.compactMap {
                UUID(uuidString: $0.attributes.occurrenceID)
            }
        )
    }

    func stateDescription(for occurrenceID: UUID) -> String? {
        guard let activity = activity(for: occurrenceID) else { return nil }

        return switch activity.activityState {
        case .pending: "pending"
        case .active: "active"
        case .stale: "stale"
        case .ended: "ended"
        case .dismissed: "dismissed"
        @unknown default: "unknown"
        }
    }

    func cancelAll(except keepOccurrenceIDs: Set<UUID>) async {
        for activity in Activity<JomadoActivityAttributes>.activities {
            guard
                let occurrenceID = UUID(uuidString: activity.attributes.occurrenceID),
                !keepOccurrenceIDs.contains(occurrenceID)
            else { continue }

            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func activity(for occurrenceID: UUID) -> Activity<JomadoActivityAttributes>? {
        Activity<JomadoActivityAttributes>.activities.first {
            $0.attributes.occurrenceID == occurrenceID.uuidString
        }
    }

    private func makeAttributes(
        occurrence: ReminderOccurrence,
        mascotID: String
    ) -> JomadoActivityAttributes {
        JomadoActivityAttributes(
            occurrenceID: occurrence.id.uuidString,
            routineID: occurrence.routineID.uuidString,
            routineType: occurrence.routineType,
            routineName: occurrence.routineName,
            completionLabel: occurrence.completionLabel,
            mascotID: mascotID
        )
    }

    private func makeState(
        occurrence: ReminderOccurrence,
        presentation: ReminderPresentation
    ) -> JomadoActivityAttributes.ContentState {
        JomadoActivityAttributes.ContentState(
            stage: presentation.stage,
            headline: presentation.content.variants.liveActivity.headline,
            message: presentation.content.variants.liveActivity.body,
            compactStatus: presentation.statusText,
            dueDate: occurrence.dueDate,
            expression: presentation.content.mascot.expression,
            animationCue: presentation.content.mascot.animationCue,
            isCompleted: occurrence.status == .completed
        )
    }
}
