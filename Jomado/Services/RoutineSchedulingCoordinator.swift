import Foundation
import SwiftData
import UserNotifications

@MainActor
final class RoutineSchedulingCoordinator {
    private let modelContext: ModelContext
    private let notificationScheduler: NotificationScheduler
    private let alarmScheduler: AlarmScheduler
    private let contentRepository: ContentRepository
    private let horizonDays: Int
    private let maximumPrimaryNotifications: Int

    init(
        modelContext: ModelContext,
        notificationScheduler: NotificationScheduler = .shared,
        alarmScheduler: AlarmScheduler = .shared,
        contentRepository: ContentRepository,
        horizonDays: Int = 7,
        maximumPrimaryNotifications: Int = 48
    ) {
        self.modelContext = modelContext
        self.notificationScheduler = notificationScheduler
        self.alarmScheduler = alarmScheduler
        self.contentRepository = contentRepository
        self.horizonDays = horizonDays
        self.maximumPrimaryNotifications = maximumPrimaryNotifications
    }

    @discardableResult
    func save(_ draft: RoutineDraft, now: Date = .now) async throws -> RoutineEntity {
        let entity = RoutineEntity(instance: draft.materialize(now: now))
        modelContext.insert(entity)
        try modelContext.save()
        await reconcile(now: now)
        return entity
    }

    func saveStarterRoutines(_ drafts: [RoutineDraft], now: Date = .now) async throws {
        let existingTypes = Set(try fetchAllRoutines().map(\.routineType))
        var inserted = false

        for draft in drafts where !existingTypes.contains(draft.type) {
            modelContext.insert(RoutineEntity(instance: draft.materialize(now: now)))
            inserted = true
        }

        guard inserted else { return }
        try modelContext.save()
        await reconcile(now: now)
    }

    func update(routineID: UUID, draft: RoutineDraft, now: Date = .now) async throws {
        guard let routine = try fetchRoutine(id: routineID), routine.archivedAt == nil else { return }
        routine.apply(draft, now: now)
        try modelContext.save()
        await reconcile(now: now)
    }

    func setEnabled(routineID: UUID, enabled: Bool, now: Date = .now) async throws {
        guard let routine = try fetchRoutine(id: routineID) else { return }
        routine.enabled = enabled
        routine.updatedAt = now
        try modelContext.save()
        await reconcile(now: now)
    }

    func delete(routineID: UUID, now: Date = .now) async throws {
        guard let routine = try fetchRoutine(id: routineID) else { return }
        routine.enabled = false
        routine.archivedAt = now
        routine.updatedAt = now

        let occurrences = try fetchOccurrences(routineID: routineID)
        let unresolved = occurrences.filter { !$0.status.isTerminal }
        let identifiers = unresolved.compactMap(\.notificationID)
        let alarmIDs = unresolved.map(\.id)

        for occurrence in unresolved {
            if occurrence.scheduledAt <= now {
                occurrence.status = .expired
                occurrence.resolvedAt = now
                occurrence.followUpDate = nil
                occurrence.followUpContentID = nil
                occurrence.notificationID = nil
            } else {
                modelContext.delete(occurrence)
            }
        }

        try modelContext.save()
        await notificationScheduler.cancel(requestIdentifiers: identifiers)
        alarmScheduler.cancel(ids: alarmIDs)
        await reconcile(now: now)
    }

    func reconcile(now: Date = .now) async {
        do {
            let notificationStatus = await notificationScheduler.authorizationStatus()
            let canScheduleNotification = notificationStatus == .authorized
                || notificationStatus == .provisional
                || notificationStatus == .ephemeral
            let canScheduleAlarm = alarmScheduler.authorizationStatus().canSchedule
            let systemAlarmIDs = alarmScheduler.scheduledAlarmIDs()

            let routines = try fetchEnabledRoutines()
            let horizonEnd = Calendar.current.date(byAdding: .day, value: horizonDays, to: now)
                ?? now.addingTimeInterval(TimeInterval(horizonDays * 86_400))

            var desired: [(routine: RoutineEntity, date: Date, key: String)] = []
            for routine in routines {
                let instance = routine.instance
                for date in RoutineSchedulePlanner.upcomingDates(
                    for: instance,
                    from: now,
                    through: horizonEnd
                ) {
                    desired.append((
                        routine,
                        date,
                        RoutineSchedulePlanner.occurrenceKey(routineID: routine.id, date: date)
                    ))
                }
            }
            desired.sort { $0.date < $1.date }
            desired = Array(desired.prefix(maximumPrimaryNotifications))

            let desiredKeys = Set(desired.map(\.key))
            let existingFuture = try fetchOpenOccurrences(from: now.addingTimeInterval(-60))
            var byKey = Dictionary(uniqueKeysWithValues: existingFuture.map { ($0.occurrenceKey, $0) })

            for item in desired where byKey[item.key] == nil {
                let occurrence = ReminderOccurrenceEntity(
                    routineID: item.routine.id,
                    occurrenceKey: item.key,
                    scheduledAt: item.date
                )
                modelContext.insert(occurrence)
                byKey[item.key] = occurrence
            }

            let stale = existingFuture.filter {
                !desiredKeys.contains($0.occurrenceKey) && $0.status == .scheduled
            }
            let staleNotificationIDs = stale.compactMap(\.notificationID)
            let staleAlarmIDs = stale.map(\.id)
            stale.forEach(modelContext.delete)

            if !staleNotificationIDs.isEmpty {
                await notificationScheduler.cancel(requestIdentifiers: staleNotificationIDs)
            }
            alarmScheduler.cancel(ids: staleAlarmIDs)

            // Always inspect pending notifications, even when authorization was revoked, so
            // reconciliation can remove stale or duplicate requests deterministically.
            let pendingNotifications = await notificationScheduler.pendingRequestIdentifiers()
            var selectionExposures = try fetchRecentContentExposures(now: now).map(\.exposure)
            var desiredAlarmIDs = Set<UUID>()
            var notificationCount = 0
            var alarmCount = 0

            for item in desired {
                guard let entity = byKey[item.key], entity.status == .scheduled else { continue }

                let content = await content(
                    for: entity,
                    routine: item.routine,
                    occurrenceKey: item.key,
                    scheduledAt: item.date,
                    selectionExposures: &selectionExposures
                )
                let domain = entity.domainOccurrence(for: item.routine)

                var deliveredByAlarm = false
                if item.routine.deliveryMode == .alarmAndCompanion && canScheduleAlarm {
                    if systemAlarmIDs.contains(entity.id) {
                        deliveredByAlarm = true
                    } else {
                        do {
                            try await alarmScheduler.schedule(
                                occurrence: domain,
                                content: content,
                                at: item.date
                            )
                            deliveredByAlarm = true
                            alarmCount += 1
                        } catch {
                            #if DEBUG
                            print("AlarmKit scheduling failed for \(entity.id): \(error)")
                            #endif
                        }
                    }
                }

                if deliveredByAlarm {
                    desiredAlarmIDs.insert(entity.id)
                    if let notificationID = entity.notificationID,
                       pendingNotifications.contains(notificationID) {
                        await notificationScheduler.cancel(requestIdentifiers: [notificationID])
                    }
                    entity.notificationID = nil
                    continue
                }

                if canScheduleNotification {
                    let requestID = notificationScheduler.requestIdentifier(
                        occurrenceID: entity.id,
                        isFollowUp: false
                    )
                    entity.notificationID = requestID
                    if !pendingNotifications.contains(requestID) {
                        try await notificationScheduler.schedule(
                            occurrence: domain,
                            content: content,
                            at: item.date
                        )
                        notificationCount += 1
                    }
                }
            }

            // Snoozed reminders are persisted independently of the rolling primary horizon.
            // Reconcile them as first-class desired deliveries so relaunching the app does
            // not accidentally cancel a valid AlarmKit follow-up as an orphan.
            let enabledRoutinesByID = Dictionary(uniqueKeysWithValues: routines.map { ($0.id, $0) })
            let unresolvedOccurrences = try fetchUnresolvedOccurrences()
            for entity in unresolvedOccurrences {
                let followUpRequestID = notificationScheduler.requestIdentifier(
                    occurrenceID: entity.id,
                    isFollowUp: true
                )

                guard
                    entity.status == .acknowledged,
                    let followUpDate = entity.followUpDate,
                    followUpDate > now,
                    let routine = enabledRoutinesByID[entity.routineID]
                else {
                    if pendingNotifications.contains(followUpRequestID) {
                        await notificationScheduler.cancel(requestIdentifiers: [followUpRequestID])
                    }
                    continue
                }

                let followUpContent = await content(
                    forFollowUp: entity,
                    routine: routine,
                    scheduledAt: followUpDate,
                    selectionExposures: &selectionExposures
                )
                let domain = entity.domainOccurrence(for: routine)

                var deliveredByAlarm = false
                if routine.deliveryMode == .alarmAndCompanion && canScheduleAlarm {
                    desiredAlarmIDs.insert(entity.id)
                    if systemAlarmIDs.contains(entity.id) {
                        deliveredByAlarm = true
                    } else {
                        do {
                            try await alarmScheduler.schedule(
                                occurrence: domain,
                                content: followUpContent,
                                at: followUpDate
                            )
                            deliveredByAlarm = true
                            alarmCount += 1
                        } catch {
                            // Leave the alarm out of desired state when scheduling failed so
                            // notification fallback can take over below.
                            desiredAlarmIDs.remove(entity.id)
                            #if DEBUG
                            print("AlarmKit follow-up reconciliation failed for \(entity.id): \(error)")
                            #endif
                        }
                    }
                }

                if deliveredByAlarm {
                    if pendingNotifications.contains(followUpRequestID) {
                        await notificationScheduler.cancel(requestIdentifiers: [followUpRequestID])
                    }
                    continue
                }

                if canScheduleNotification && !pendingNotifications.contains(followUpRequestID) {
                    try await notificationScheduler.schedule(
                        occurrence: domain,
                        content: followUpContent,
                        at: followUpDate,
                        isFollowUp: true
                    )
                    notificationCount += 1
                }
            }

            let orphanAlarmIDs = systemAlarmIDs.subtracting(desiredAlarmIDs)
            alarmScheduler.cancel(ids: orphanAlarmIDs)

            for routine in routines {
                routine.lastReconciledAt = now
            }
            try modelContext.save()

            #if DEBUG
            if notificationCount > 0 || alarmCount > 0 {
                print(
                    "Jomado reconciliation scheduled \(alarmCount) alarm(s) and \(notificationCount) notification(s)."
                )
            }
            #endif
        } catch {
            #if DEBUG
            print("Jomado reconciliation failed: \(error)")
            #endif
        }
    }

    func handleNotificationAction(
        _ event: NotificationActionEvent,
        now: Date = .now
    ) async throws -> ReminderOccurrence? {
        guard
            let occurrenceEntity = try fetchOccurrence(id: event.occurrenceID),
            let routine = try fetchRoutine(id: event.routineID)
        else { return nil }

        var occurrence = occurrenceEntity.domainOccurrence(for: routine)
        guard !occurrence.status.isTerminal else { return occurrence }

        switch event.action {
        case .completed:
            occurrence = try ReminderStateMachine.apply(.completed, to: occurrence, at: now)
            occurrenceEntity.apply(occurrence)
            occurrenceEntity.followUpContentID = nil
            await notificationScheduler.cancel(occurrenceID: occurrence.id)
            alarmScheduler.cancel(id: occurrence.id)

        case .remindLater:
            let followUp = now.addingTimeInterval(TimeInterval(max(1, routine.snoozeMinutes) * 60))
            occurrence = try ReminderStateMachine.apply(.snoozed(until: followUp), to: occurrence, at: now)

            await notificationScheduler.cancel(occurrenceID: occurrence.id)
            alarmScheduler.cancel(id: occurrence.id)

            guard routine.smartSnoozeEnabled, occurrence.snoozeCount <= routine.maxSnoozes else {
                // Acknowledge the action but do not retain a follow-up that the scheduler is
                // not allowed to deliver. The routine remains explicitly incomplete.
                occurrence.followUpDate = nil
                occurrenceEntity.apply(occurrence)
                occurrenceEntity.followUpContentID = nil
                break
            }

            occurrenceEntity.apply(occurrence)
            var selectionExposures = try fetchRecentContentExposures(now: now).map(\.exposure)
            let followUpContent = await content(
                forFollowUp: occurrenceEntity,
                routine: routine,
                scheduledAt: followUp,
                selectionExposures: &selectionExposures
            )

            var scheduledWithAlarm = false
            if routine.deliveryMode == .alarmAndCompanion,
               alarmScheduler.authorizationStatus().canSchedule {
                do {
                    try await alarmScheduler.schedule(
                        occurrence: occurrence,
                        content: followUpContent,
                        at: followUp
                    )
                    scheduledWithAlarm = true
                } catch {
                    #if DEBUG
                    print("AlarmKit follow-up scheduling failed: \(error)")
                    #endif
                }
            }

            if !scheduledWithAlarm {
                let status = await notificationScheduler.authorizationStatus()
                let canScheduleNotification = status == .authorized
                    || status == .provisional
                    || status == .ephemeral
                if canScheduleNotification {
                    try await notificationScheduler.schedule(
                        occurrence: occurrence,
                        content: followUpContent,
                        at: followUp,
                        isFollowUp: true
                    )
                }
            }

        case .opened:
            occurrence = try ReminderStateMachine.apply(.opened, to: occurrence, at: now)
            occurrenceEntity.apply(occurrence)

        case .dismissed:
            occurrence = try ReminderStateMachine.apply(.dismissed, to: occurrence, at: now)
            occurrenceEntity.apply(occurrence)

        case .alarmStopped:
            occurrence = try ReminderStateMachine.apply(.alarmStopped, to: occurrence, at: now)
            occurrenceEntity.apply(occurrence)
        }

        try modelContext.save()
        return occurrence
    }

    func skipOccurrence(
        occurrenceID: UUID,
        routineID: UUID,
        now: Date = .now
    ) async throws -> ReminderOccurrence? {
        guard
            let occurrenceEntity = try fetchOccurrence(id: occurrenceID),
            let routine = try fetchRoutine(id: routineID)
        else { return nil }

        var occurrence = occurrenceEntity.domainOccurrence(for: routine)
        guard !occurrence.status.isTerminal else { return occurrence }
        occurrence = try ReminderStateMachine.apply(.skipped, to: occurrence, at: now)
        occurrenceEntity.apply(occurrence)
        occurrenceEntity.followUpContentID = nil
        try modelContext.save()
        await notificationScheduler.cancel(occurrenceID: occurrence.id)
        alarmScheduler.cancel(id: occurrence.id)
        return occurrence
    }

    func openOccurrence(
        occurrenceID: UUID,
        now: Date = .now
    ) async throws -> ReminderOccurrence? {
        guard
            let occurrenceEntity = try fetchOccurrence(id: occurrenceID),
            let routine = try fetchRoutine(id: occurrenceEntity.routineID)
        else { return nil }

        var occurrence = occurrenceEntity.domainOccurrence(for: routine)
        if !occurrence.status.isTerminal {
            occurrence = try ReminderStateMachine.apply(.opened, to: occurrence, at: now)
            occurrenceEntity.apply(occurrence)
            try modelContext.save()
        }
        return occurrence
    }

    func routine(for id: UUID) throws -> RoutineEntity? {
        try fetchRoutine(id: id)
    }

    private func content(
        for entity: ReminderOccurrenceEntity,
        routine: RoutineEntity,
        occurrenceKey: String,
        scheduledAt: Date,
        selectionExposures: inout [ContentExposure]
    ) async -> ReminderContentItem {
        if let contentID = entity.contentID,
           let existingContent = await contentRepository.item(id: contentID) {
            return existingContent
        }

        let selected = await contentRepository.select(
            context: ContentSelectionContext(
                routineID: routine.id,
                routineType: routine.routineType,
                stage: .normal,
                personality: routine.personality(for: occurrenceKey),
                intensity: routine.intensity,
                locale: "en",
                occurrenceSlot: occurrenceKey,
                date: scheduledAt
            ),
            exposures: selectionExposures
        )
        entity.contentID = selected.id
        let exposureEntity = ContentExposureEntity(
            contentID: selected.id,
            occurrenceID: entity.id,
            semanticFamily: selected.semanticFamily,
            expression: selected.mascot.expression,
            animationCue: selected.mascot.animationCue,
            shownAt: scheduledAt
        )
        modelContext.insert(exposureEntity)
        selectionExposures.append(exposureEntity.exposure)
        return selected
    }

    private func content(
        forFollowUp entity: ReminderOccurrenceEntity,
        routine: RoutineEntity,
        scheduledAt: Date,
        selectionExposures: inout [ContentExposure]
    ) async -> ReminderContentItem {
        if let contentID = entity.followUpContentID,
           let existingContent = await contentRepository.item(id: contentID) {
            return existingContent
        }

        let selected = await contentRepository.select(
            context: ContentSelectionContext(
                routineID: routine.id,
                routineType: routine.routineType,
                stage: ReminderUrgencyStage.resolve(dueDate: entity.scheduledAt, now: scheduledAt),
                personality: routine.personality(for: entity.occurrenceKey + ".snooze.\(entity.snoozeCount)"),
                intensity: routine.intensity,
                locale: "en",
                occurrenceSlot: entity.occurrenceKey + ".snooze.\(entity.snoozeCount)",
                date: scheduledAt
            ),
            exposures: selectionExposures
        )
        entity.followUpContentID = selected.id
        let exposureEntity = ContentExposureEntity(
            contentID: selected.id,
            occurrenceID: entity.id,
            semanticFamily: selected.semanticFamily,
            expression: selected.mascot.expression,
            animationCue: selected.mascot.animationCue,
            shownAt: scheduledAt
        )
        modelContext.insert(exposureEntity)
        selectionExposures.append(exposureEntity.exposure)
        return selected
    }

    private func fetchAllRoutines() throws -> [RoutineEntity] {
        let descriptor = FetchDescriptor<RoutineEntity>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchEnabledRoutines() throws -> [RoutineEntity] {
        let descriptor = FetchDescriptor<RoutineEntity>(
            predicate: #Predicate { $0.enabled == true && $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchRoutine(id: UUID) throws -> RoutineEntity? {
        let descriptor = FetchDescriptor<RoutineEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchOccurrence(id: UUID) throws -> ReminderOccurrenceEntity? {
        let descriptor = FetchDescriptor<ReminderOccurrenceEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchOccurrences(routineID: UUID) throws -> [ReminderOccurrenceEntity] {
        let descriptor = FetchDescriptor<ReminderOccurrenceEntity>(
            predicate: #Predicate { $0.routineID == routineID }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchRecentContentExposures(now: Date) throws -> [ContentExposureEntity] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: now)
            ?? now.addingTimeInterval(-14 * 86_400)
        let descriptor = FetchDescriptor<ContentExposureEntity>(
            predicate: #Predicate { $0.shownAt >= cutoff },
            sortBy: [SortDescriptor(\.shownAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchOpenOccurrences(from date: Date) throws -> [ReminderOccurrenceEntity] {
        let descriptor = FetchDescriptor<ReminderOccurrenceEntity>(
            predicate: #Predicate { $0.scheduledAt >= date },
            sortBy: [SortDescriptor(\.scheduledAt)]
        )
        return try modelContext.fetch(descriptor).filter { !$0.status.isTerminal }
    }

    private func fetchUnresolvedOccurrences() throws -> [ReminderOccurrenceEntity] {
        let descriptor = FetchDescriptor<ReminderOccurrenceEntity>(
            sortBy: [SortDescriptor(\.scheduledAt)]
        )
        return try modelContext.fetch(descriptor).filter { !$0.status.isTerminal }
    }
}
