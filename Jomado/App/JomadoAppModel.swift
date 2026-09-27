import Combine
import Foundation
import SwiftData

enum JomadoTab: Hashable {
    case today
    case routines
    case insights
    case settings
}

@MainActor
final class JomadoAppModel: ObservableObject {
    @Published private(set) var occurrence: ReminderOccurrence
    @Published private(set) var presentation: ReminderPresentation
    @Published private(set) var activeSnoozeMinutes: Int?
    @Published private(set) var snoozeUnavailableMessage: String?
    @Published private(set) var activeMascotID = CompanionMascot.momo.rawValue
    @Published var isReminderPresented = false
    @Published var selectedTab: JomadoTab = .today
    @Published private(set) var systemMessage: String?

    private let contentRepository = ContentRepository()
    private let notificationScheduler = NotificationScheduler.shared
    private let alarmScheduler = AlarmScheduler.shared
    private let liveActivityCoordinator = LiveActivityCoordinator()
    private let verificationRegistry = CompletionVerificationRegistry()
    private var routineCoordinator: RoutineSchedulingCoordinator?
    private var exposures: [ContentExposure] = []
    private var isBootstrapped = false

    var liveActivitiesEnabled: Bool {
        liveActivityCoordinator.activitiesEnabled
    }

    init(now: Date = .now) {
        let occurrence = Self.makeDemoOccurrence(now: now)
        self.occurrence = occurrence
        self.presentation = ReminderPresentation(
            stage: .normal,
            content: .safeFallback,
            statusText: "Due now"
        )
    }

    func configure(modelContext: ModelContext) {
        guard routineCoordinator == nil else { return }
        routineCoordinator = RoutineSchedulingCoordinator(
            modelContext: modelContext,
            notificationScheduler: notificationScheduler,
            contentRepository: contentRepository
        )
    }

    func bootstrap() async {
        guard !isBootstrapped else { return }
        isBootstrapped = true

        await notificationScheduler.registerCategories()
        await contentRepository.loadBundledPack()
        await routineCoordinator?.reconcile()
        await refreshPresentation(at: .now, force: true)

        NotificationActionRouter.shared.install { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                _ = await self.handleNotificationAction(event)
            }
        }
        await drainExternalEvents()
    }

    func drainExternalEvents() async {
        for externalEvent in JomadoExternalEventQueue.pendingEvents() {
            let action: NotificationActionKind = switch externalEvent.action {
            case .alarmStopped: .alarmStopped
            case .opened: .opened
            }
            let handled = await handleNotificationAction(
                NotificationActionEvent(
                    action: action,
                    occurrenceID: externalEvent.occurrenceID,
                    routineID: externalEvent.routineID
                )
            )
            if handled {
                JomadoExternalEventQueue.acknowledge(eventID: externalEvent.id)
            }
        }
    }

    func reconcileSchedules() async {
        await routineCoordinator?.reconcile()
    }

    func saveRoutine(_ draft: RoutineDraft) async {
        do {
            _ = try await routineCoordinator?.save(draft)

            if draft.deliveryMode == .alarmAndCompanion,
               alarmScheduler.authorizationStatus() == .notDetermined {
                do {
                    let granted = try await alarmScheduler.requestAuthorization()
                    await routineCoordinator?.reconcile()
                    systemMessage = granted
                        ? "Routine saved. Alarm + Companion delivery is ready."
                        : "Routine saved. Alarm access is off, so Jomado will use notification fallback when available."
                } catch {
                    systemMessage = "Routine saved, but alarm permission could not be requested: \(error.localizedDescription)"
                }
            } else {
                systemMessage = "Routine saved and delivery schedule refreshed."
            }
        } catch {
            systemMessage = "The routine could not be saved: \(error.localizedDescription)"
        }
    }

    func createStarterRoutines(for types: Set<RoutineType>) async {
        guard let routineCoordinator else { return }

        let personalities = Self.decodePersonalities(UserDefaults.standard.string(forKey: "jomado.defaultPersonality") ?? "")
        let intensity = ReminderIntensity(
            rawValue: UserDefaults.standard.string(forKey: "jomado.defaultIntensity") ?? ""
        ) ?? .balanced
        let drafts = types
            .sorted { $0.rawValue < $1.rawValue }
            .compactMap { Self.starterDraft(for: $0, personalities: personalities, intensity: intensity) }

        guard !drafts.isEmpty else { return }

        do {
            try await routineCoordinator.saveStarterRoutines(drafts)
            systemMessage = drafts.count == 1
                ? "Your starter routine is ready."
                : "Your starter routines are ready."
        } catch {
            systemMessage = "Starter routines could not be created: \(error.localizedDescription)"
        }
    }

    func updateRoutine(id: UUID, draft: RoutineDraft) async {
        do {
            try await routineCoordinator?.update(routineID: id, draft: draft)
            systemMessage = "Routine updated and delivery schedule refreshed."
        } catch {
            systemMessage = "The routine could not be updated: \(error.localizedDescription)"
        }
    }

    func setRoutineEnabled(id: UUID, enabled: Bool) async {
        do {
            try await routineCoordinator?.setEnabled(routineID: id, enabled: enabled)
        } catch {
            systemMessage = "The routine could not be updated: \(error.localizedDescription)"
        }
    }

    func deleteRoutine(id: UUID) async {
        do {
            try await routineCoordinator?.delete(routineID: id)
        } catch {
            systemMessage = "The routine could not be deleted: \(error.localizedDescription)"
        }
    }

    func openOccurrence(occurrenceID: UUID, routineID: UUID) async {
        guard let coordinator = routineCoordinator else { return }
        do {
            let event = NotificationActionEvent(
                action: .opened,
                occurrenceID: occurrenceID,
                routineID: routineID
            )
            guard let persisted = try await coordinator.handleNotificationAction(event) else { return }
            occurrence = persisted
            exposures.removeAll()
            await refreshPresentation(at: .now, force: true)
            isReminderPresented = true
        } catch {
            systemMessage = "The reminder could not be opened: \(error.localizedDescription)"
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

        do {
            let verifier = verificationRegistry.verifier(for: occurrence.routineType)
            let result = try await verifier.verify(
                CompletionVerificationRequest(
                    occurrenceID: occurrence.id,
                    routineID: occurrence.routineID,
                    routineType: occurrence.routineType,
                    requestedAt: .now
                )
            )
            guard result.isVerified else {
                systemMessage = "Completion could not be verified."
                return
            }
        } catch {
            systemMessage = "Completion verification failed: \(error.localizedDescription)"
            return
        }

        var persistedUpdateApplied = false
        if let coordinator = routineCoordinator {
            do {
                let event = NotificationActionEvent(
                    action: .completed,
                    occurrenceID: occurrence.id,
                    routineID: occurrence.routineID
                )
                if let persisted = try await coordinator.handleNotificationAction(event) {
                    occurrence = persisted
                    persistedUpdateApplied = true
                }
            } catch {
                systemMessage = "Completion could not be persisted: \(error.localizedDescription)"
            }
        }

        if !persistedUpdateApplied {
            occurrence = (try? ReminderStateMachine.apply(.completed, to: occurrence)) ?? occurrence
            await notificationScheduler.clear(occurrenceID: occurrence.id)
        }

        await refreshPresentation(at: .now, force: true)
        await liveActivityCoordinator.update(occurrence: occurrence, presentation: presentation)
        await liveActivityCoordinator.end(
            occurrence: occurrence,
            presentation: presentation,
            immediate: false
        )
    }

    func remindLater(closeAfter: Bool = true) async {
        guard !occurrence.status.isTerminal else { return }
        guard let minutes = activeSnoozeMinutes, snoozeUnavailableMessage == nil else {
            systemMessage = snoozeUnavailableMessage
                ?? "Remind later is unavailable for this routine."
            return
        }

        var persistedUpdateApplied = false
        if let coordinator = routineCoordinator {
            do {
                let event = NotificationActionEvent(
                    action: .remindLater,
                    occurrenceID: occurrence.id,
                    routineID: occurrence.routineID
                )
                if let persisted = try await coordinator.handleNotificationAction(event) {
                    occurrence = persisted
                    persistedUpdateApplied = true
                    systemMessage = "Reminder moved by \(minutes) minutes. It is still incomplete."
                }
            } catch {
                systemMessage = "The follow-up could not be persisted: \(error.localizedDescription)"
            }
        }

        if !persistedUpdateApplied {
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
        }

        await refreshPresentation(at: .now, force: true)
        if closeAfter { isReminderPresented = false }
    }

    func skip() async {
        guard !occurrence.status.isTerminal else { return }

        var persistedUpdateApplied = false
        if let coordinator = routineCoordinator {
            do {
                if let persisted = try await coordinator.skipOccurrence(
                    occurrenceID: occurrence.id,
                    routineID: occurrence.routineID
                ) {
                    occurrence = persisted
                    persistedUpdateApplied = true
                }
            } catch {
                systemMessage = "Skip could not be persisted: \(error.localizedDescription)"
            }
        }

        if !persistedUpdateApplied {
            occurrence = (try? ReminderStateMachine.apply(.skipped, to: occurrence)) ?? occurrence
            await notificationScheduler.clear(occurrenceID: occurrence.id)
        }

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

    @discardableResult
    func requestNotificationAuthorization() async -> Bool {
        do {
            let granted = try await notificationScheduler.requestAuthorization()
            systemMessage = granted
                ? "Notifications are ready."
                : "Notifications are off. You can enable them later in Settings."
            return granted
        } catch {
            systemMessage = "Notification permission could not be requested: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func requestAlarmAuthorization() async -> Bool {
        do {
            let granted = try await alarmScheduler.requestAuthorization()
            await routineCoordinator?.reconcile()
            systemMessage = granted
                ? "Alarm + Companion delivery is ready."
                : "Alarm access is off. Alarm routines will use notification fallback when available."
            return granted
        } catch {
            systemMessage = "Alarm permission could not be requested: \(error.localizedDescription)"
            return false
        }
    }

    func startLiveActivity() async {
        do {
            try await liveActivityCoordinator.start(
                occurrence: occurrence,
                presentation: presentation,
                mascotID: activeMascotID
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

        if url.host == "today" {
            selectedTab = .today
            return
        }

        guard
            url.host == "occurrence",
            let rawID = url.pathComponents.dropFirst().first,
            let occurrenceID = UUID(uuidString: rawID)
        else { return }

        Task { @MainActor in
            await openOccurrence(occurrenceID: occurrenceID)
        }
    }

    private func openOccurrence(occurrenceID: UUID) async {
        guard let coordinator = routineCoordinator else { return }
        do {
            guard let persisted = try await coordinator.openOccurrence(occurrenceID: occurrenceID) else {
                systemMessage = "That reminder is no longer available."
                return
            }
            occurrence = persisted
            exposures.removeAll()
            await refreshPresentation(at: .now, force: true)
            selectedTab = .today
            isReminderPresented = !persisted.status.isTerminal
        } catch {
            systemMessage = "The reminder could not be opened: \(error.localizedDescription)"
        }
    }

    @discardableResult
    private func handleNotificationAction(_ event: NotificationActionEvent) async -> Bool {
        if let coordinator = routineCoordinator {
            do {
                if let persisted = try await coordinator.handleNotificationAction(event) {
                    occurrence = persisted
                    exposures.removeAll()
                    await refreshPresentation(at: .now, force: true)

                    if event.action == .opened {
                        isReminderPresented = true
                    } else if event.action == .completed {
                        await liveActivityCoordinator.end(
                            occurrence: occurrence,
                            presentation: presentation,
                            immediate: false
                        )
                    }
                    return true
                }
            } catch {
                systemMessage = "The reminder action could not be saved: \(error.localizedDescription)"
                return false
            }
        }

        guard event.occurrenceID == occurrence.id, event.routineID == occurrence.routineID else {
            return true
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
        case .alarmStopped:
            occurrence = (
                try? ReminderStateMachine.apply(.alarmStopped, to: occurrence)
            ) ?? occurrence
        }
        return true
    }

    private func refreshPresentation(at now: Date, force: Bool = false) async {
        let stage = ReminderUrgencyStage.resolve(
            dueDate: occurrence.dueDate,
            now: now,
            isCompleted: occurrence.status == .completed
        )
        guard force || stage != presentation.stage else { return }

        var storedRoutine: RoutineEntity?
        if let coordinator = routineCoordinator {
            storedRoutine = try? coordinator.routine(for: occurrence.routineID)
        } else {
            storedRoutine = nil
        }

        if let storedRoutine {
            if !storedRoutine.smartSnoozeEnabled {
                activeSnoozeMinutes = nil
                snoozeUnavailableMessage = "Remind later is off for this routine."
            } else if occurrence.snoozeCount >= max(0, storedRoutine.maxSnoozes) {
                activeSnoozeMinutes = nil
                snoozeUnavailableMessage = "Snooze limit reached for this reminder."
            } else {
                activeSnoozeMinutes = max(1, storedRoutine.snoozeMinutes)
                snoozeUnavailableMessage = nil
            }
        } else {
            activeSnoozeMinutes = nil
            snoozeUnavailableMessage = "Remind later is unavailable for this routine."
        }

        let occurrenceSlot = occurrence.dueDate.formatted(.dateTime.year().month().day().hour().minute())
        activeMascotID = storedRoutine?.mascotID(for: occurrenceSlot) ?? CompanionMascot.momo.rawValue
        let context = ContentSelectionContext(
            routineID: occurrence.routineID,
            routineType: occurrence.routineType,
            stage: stage,
            personality: storedRoutine?.personality(for: occurrenceSlot) ?? .playful,
            intensity: storedRoutine?.intensity ?? .balanced,
            locale: "en",
            occurrenceSlot: occurrenceSlot,
            date: now
        )
        let selectedContent = await contentRepository.select(context: context, exposures: exposures)
        let content = storedRoutine?.contentTipEnabled == false
            ? selectedContent.replacingInAppTip(nil)
            : selectedContent
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

    private static func starterDraft(
        for type: RoutineType,
        personalities: Set<ReminderPersonality>,
        intensity: ReminderIntensity
    ) -> RoutineDraft? {
        let personality = personalities.sorted { $0.rawValue < $1.rawValue }.first ?? .playful
        let daily = Set(Weekday.allCases)
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let schedule: RoutineSchedule

        switch type {
        case .hydration:
            schedule = .interval(
                start: LocalTime(hour: 8, minute: 0),
                end: LocalTime(hour: 22, minute: 0),
                everyMinutes: 120,
                weekdays: daily
            )
        case .eyeCare:
            schedule = .interval(
                start: LocalTime(hour: 9, minute: 0),
                end: LocalTime(hour: 18, minute: 0),
                everyMinutes: 60,
                weekdays: weekdays
            )
        case .posture:
            schedule = .interval(
                start: LocalTime(hour: 9, minute: 0),
                end: LocalTime(hour: 18, minute: 0),
                everyMinutes: 90,
                weekdays: weekdays
            )
        case .exercise:
            schedule = .fixed(times: [LocalTime(hour: 18, minute: 0)], weekdays: [.monday, .wednesday, .friday])
        case .stretching:
            schedule = .fixed(
                times: [LocalTime(hour: 8, minute: 0), LocalTime(hour: 20, minute: 0)],
                weekdays: daily
            )
        case .breathing:
            schedule = .fixed(times: [LocalTime(hour: 12, minute: 0)], weekdays: daily)
        case .meditation:
            schedule = .fixed(times: [LocalTime(hour: 7, minute: 0)], weekdays: daily)
        case .yoga:
            schedule = .fixed(times: [LocalTime(hour: 7, minute: 30)], weekdays: daily)
        case .sleep:
            schedule = .fixed(times: [LocalTime(hour: 22, minute: 30)], weekdays: daily)
        case .custom, .generic:
            return nil
        }

        return RoutineDraft(
            type: type,
            name: type.displayName,
            schedule: schedule,
            deliveryMode: .companionOnly,
            personality: personality,
            personalityPoolRaw: personalities.sorted { $0.rawValue < $1.rawValue }.map(\.rawValue).joined(separator: "|"),
            intensity: intensity,
            smartSnoozeEnabled: true,
            snoozeMinutes: 10,
            maxSnoozes: 3,
            goal: type == .hydration ? "Build a steady hydration habit" : nil
        )
    }

    private static func decodePersonalities(_ raw: String) -> Set<ReminderPersonality> {
        let values = raw.split(separator: "|").compactMap { ReminderPersonality(rawValue: String($0)) }
        return Set(values.isEmpty ? [.playful] : values)
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
