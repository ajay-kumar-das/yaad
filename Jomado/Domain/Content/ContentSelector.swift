import Foundation

struct ContentSelectionContext: Hashable, Sendable {
    let routineID: UUID
    let routineType: RoutineType
    let stage: ReminderUrgencyStage
    let personality: ReminderPersonality
    let intensity: ReminderIntensity
    let locale: String
    let occurrenceSlot: String
    let date: Date
}

enum ContentSelector {
    static func select(
        from items: [ReminderContentItem],
        context: ContentSelectionContext,
        exposures: [ContentExposure],
        topK: Int = 4,
        calendar: Calendar = .current
    ) -> ReminderContentItem? {
        let eligible = items.filter {
            $0.enabled
                && ($0.routineType == context.routineType || $0.routineType == .generic)
                && $0.stage == context.stage
                && $0.personality == context.personality
                && $0.locale == context.locale
        }

        guard !eligible.isEmpty else { return nil }

        let outsideCooldown = eligible.filter { item in
            let cooldown = TimeInterval(item.cooldownMinutes * 60)
            return !exposures.contains {
                $0.contentID == item.id && context.date.timeIntervalSince($0.shownAt) < cooldown
            }
        }

        let candidatePool = outsideCooldown.isEmpty ? eligible : outsideCooldown
        let daypart = ContentDaypart.resolve(for: context.date, calendar: calendar)
        let dayStart = calendar.startOfDay(for: context.date)

        let ranked = candidatePool
            .map { item in
                (item, score(item, context: context, exposures: exposures, daypart: daypart, dayStart: dayStart))
            }
            .sorted {
                if $0.1 == $1.1 { return $0.0.id < $1.0.id }
                return $0.1 > $1.1
            }

        let finalists = Array(ranked.prefix(max(1, topK)))
        let dateParts = calendar.dateComponents([.year, .month, .day], from: context.date)
        let dayKey = "\(dateParts.year ?? 0)-\(dateParts.month ?? 0)-\(dateParts.day ?? 0)"
        let seed = stableHash(
            "\(context.routineID.uuidString)|\(context.occurrenceSlot)|\(context.stage.rawValue)|\(dayKey)"
        )
        return finalists[Int(seed % UInt64(finalists.count))].0
    }

    private static func score(
        _ item: ReminderContentItem,
        context: ContentSelectionContext,
        exposures: [ContentExposure],
        daypart: ContentDaypart,
        dayStart: Date
    ) -> Int {
        var value = item.priority

        value += item.routineType == context.routineType ? 100 : 25
        value += item.intensity == context.intensity ? 30 : 0
        value += item.dayparts.contains(.any) || item.dayparts.contains(daypart) ? 15 : 0
        value += exposures.contains(where: { $0.contentID == item.id }) ? 0 : 20

        if exposures.contains(where: { $0.contentID == item.id && $0.shownAt >= dayStart }) {
            value -= 100
        }
        if exposures.contains(where: { $0.semanticFamily == item.semanticFamily && $0.shownAt >= dayStart }) {
            value -= 40
        }
        if exposures.last?.expression == item.mascot.expression {
            value -= 15
        }
        if exposures.last?.animationCue == item.mascot.animationCue {
            value -= 8
        }

        return value
    }

    private static func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
