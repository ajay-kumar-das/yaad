import Combine
import Foundation

@MainActor
final class JomadoAppModel: ObservableObject {
    @Published private(set) var occurrence: ReminderOccurrence
    @Published private(set) var presentation: ReminderPresentation
    @Published var isReminderPresented = false
    @Published private(set) var systemMessage: String?

    private let contentRepository = ContentRepository()
    private let notificationScheduler = NotificationScheduler.shared
    private let liveActivityCoordinator = LiveActivityCoordinator()
    private var exposures: [ContentExposure] = []
    private var isBootstrapped = false

    init(now: Date = .now) {
        let occurrence = Self.makeDemoOccurrence(now: now)
        self.occurrence = occurrence
        self.presentation = ReminderPresentation(
            stage: .normal,
            content: .safeFallback,
            statusText: "Due now"
        )
    }

    func bootstrap() async {
        guard !isBootstrapped else { return }
        isBootstrapped = true

        await notificationScheduler.registerCategories()
        await contentRepository.loadBundledPack()
        await refreshPresentation(at: .now, force: true)

        NotificationActionRouter.shared.install { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                await self.handleNotificationAction(event)
            }
        }
    }

    func openReminder() {
        guard !occurrence.status.isTerminal else { return }
        occurrence = (try? ReminderStateMachine.apply(.opened, to: occurrence)) ?? occurrence
        isReminderPresented = true
    }

    func closeReminder() {
        isReminderPresented = false
    }

    func tick(at now: Date = .now) async {
        await refreshPresentation(at: now)
    }

    func complete() async {
        guard !occurrence.status.isTerminal else { return }
        occurrence = (try? ReminderStateMachine.apply(.completed, to: occurrence)) ?? occurrence
        await refreshPresentation(at: .now, force: true)
        await notificationScheduler.cancel(occurrenceID: occurrence.id)
        await liveActivityCoordinator.update(occurrence: occurrence, presentation: presentation)
        await liveActivityCoordinator.end(
            occurrence: occurrence,
            presentation: presentation,
            immediate: false
        )
    }

    func remindLater(minutes: Int = 10, closeAfter: Bool = true) async {
        guard !occurrence.status.isTerminal else { return }
        let followUp = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        occurrence = (
            try? ReminderStateMachine.apply(.snoozed(until: followUp), to: occurrence)
        ) ?? occurrence

        do {
            try await notificationScheduler.schedule(
                occurrence: occurrence,
                content: presentation.content,
                at: followUp,
                isFollowUp: true
            )
            systemMessage = "Reminder moved by \(minutes) minutes. It is still incomplete."
        } catch {
            systemMessage = "The follow-up could not be scheduled: \(error.localizedDescription)"
        }

        if closeAfter { isReminderPresented = false }
    }

    func skip() async {
        guard !occurrence.status.isTerminal else { return }
        occurrence = (try? ReminderStateMachine.apply(.skipped, to: occurrence)) ?? occurrence
        await notificationScheduler.cancel(occurrenceID: occurrence.id)
        await liveActivityCoordinator.end(
            occurrence: occurrence,
            presentation: presentation,
            immediate: true
        )
        isReminderPresented = false
    }

    func requestNotificationsAndSchedulePreview() async {
        do {
            let granted = try await notificationScheduler.requestAuthorization()
            guard granted else {
                systemMessage = "Notifications are off. Routines still work inside Jomado."
                return
            }
            try await notificationScheduler.schedule(
                occurrence: occurrence,
                content: presentation.content,
                at: .now.addingTimeInterval(5)
            )
            systemMessage = "A preview notification will arrive in about 5 seconds."
        } catch {
            systemMessage = "The preview notification could not be scheduled: \(error.localizedDescription)"
        }
    }

    func startLiveActivity() async {
        do {
            try await liveActivityCoordinator.start(
                occurrence: occurrence,
                presentation: presentation
            )
            systemMessage = liveActivityCoordinator.activitiesEnabled
                ? "The Jomado Live Activity is active."
                : "Live Activities are disabled in system settings."
        } catch {
            systemMessage = "The Live Activity could not start: \(error.localizedDescription)"
        }
    }

    func resetPreview(now: Date = .now) async {
        occurrence = Self.makeDemoOccurrence(now: now)
        exposures.removeAll()
        await refreshPresentation(at: now, force: true)
        systemMessage = nil
    }

    #if DEBUG
    func preview(stage: ReminderUrgencyStage, now: Date = .now) async {
        let secondsLate: TimeInterval = switch stage {
        case .normal: 0
        case .lightOverdue: 180
        case .mediumOverdue: 600
        case .redZone: 1_200
        case .completed: 0
        }

        occurrence = Self.makeDemoOccurrence(
            now: now.addingTimeInterval(-secondsLate)
        )
        exposures.removeAll()
        await refreshPresentation(at: now, force: true)

        if stage == .completed {
            await complete()
        }
        isReminderPresented = true
    }
    #endif

    func handle(url: URL) {
        guard url.scheme == "jomado" else { return }
        if url.host == "occurrence" || url.host == "today" {
            openReminder()
        }
    }

    private func handleNotificationAction(_ event: NotificationActionEvent) async {
        guard event.occurrenceID == occurrence.id, event.routineID == occurrence.routineID else {
            return
        }

        switch event.action {
        case .completed:
            await complete()
        case .remindLater:
            await remindLater(closeAfter: false)
        case .opened:
            openReminder()
        case .dismissed:
            occurrence = (
                try? ReminderStateMachine.apply(.dismissed, to: occurrence)
            ) ?? occurrence
        }
    }

    private func refreshPresentation(at now: Date, force: Bool = false) async {
        let stage = ReminderUrgencyStage.resolve(
            dueDate: occurrence.dueDate,
            now: now,
            isCompleted: occurrence.status == .completed
        )
        guard force || stage != presentation.stage else { return }

        let context = ContentSelectionContext(
            routineID: occurrence.routineID,
            routineType: occurrence.routineType,
            stage: stage,
            personality: .playful,
            intensity: .balanced,
            locale: "en",
            occurrenceSlot: occurrence.dueDate.formatted(.dateTime.year().month().day().hour().minute()),
            date: now
        )
        let content = await contentRepository.select(context: context, exposures: exposures)
        let statusText = ReminderPresentation.statusText(
            stage: stage,
            dueDate: occurrence.dueDate,
            now: now
        )
        presentation = ReminderPresentation(stage: stage, content: content, statusText: statusText)
        exposures.append(
            ContentExposure(
                contentID: content.id,
                semanticFamily: content.semanticFamily,
                expression: content.mascot.expression,
                animationCue: content.mascot.animationCue,
                shownAt: now
            )
        )

        if !occurrence.status.isTerminal {
            await liveActivityCoordinator.update(occurrence: occurrence, presentation: presentation)
        }
    }

    private static func makeDemoOccurrence(now: Date) -> ReminderOccurrence {
        ReminderOccurrence(
            id: UUID(uuidString: "A11CE000-0000-4000-8000-000000000001")!,
            routineID: UUID(uuidString: "A11CE000-0000-4000-8000-000000000002")!,
            routineType: .hydration,
            routineName: "Drink water",
            completionLabel: RoutineType.hydration.defaultCompletionLabel,
            dueDate: now,
            status: .scheduled,
            snoozeCount: 0,
            followUpDate: nil,
            completedAt: nil,
            resolvedAt: nil
        )
    }
}
