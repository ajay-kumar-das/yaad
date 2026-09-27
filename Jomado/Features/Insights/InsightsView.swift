import SwiftData
import SwiftUI

struct InsightsView: View {
    @Query(sort: \RoutineEntity.createdAt) private var routines: [RoutineEntity]
    @Query(sort: \ReminderOccurrenceEntity.scheduledAt) private var occurrences: [ReminderOccurrenceEntity]
    @State private var period: InsightPeriod = .week

    private var calendar: Calendar { .current }

    private var filteredOccurrences: [ReminderOccurrenceEntity] {
        let now = Date.now
        switch period {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? .distantPast
            return occurrences.filter { $0.scheduledAt >= start && $0.scheduledAt <= now }
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) ?? .distantPast
            return occurrences.filter { $0.scheduledAt >= start && $0.scheduledAt <= now }
        case .allTime:
            return occurrences.filter { $0.scheduledAt <= now }
        }
    }

    private var completed: [ReminderOccurrenceEntity] { filteredOccurrences.filter { $0.status == .completed } }
    private var skipped: [ReminderOccurrenceEntity] { filteredOccurrences.filter { $0.status == .skipped } }
    private var expired: [ReminderOccurrenceEntity] { filteredOccurrences.filter { $0.status == .expired } }
    private var open: [ReminderOccurrenceEntity] { filteredOccurrences.filter { !$0.status.isTerminal } }
    private var resolvedCount: Int { completed.count + skipped.count + expired.count }
    private var completionRate: Double {
        guard resolvedCount > 0 else { return 0 }
        return Double(completed.count) / Double(resolvedCount)
    }

    private var week: [InsightDay] {
        let today = calendar.startOfDay(for: .now)
        return (-6...0).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            let values = occurrences.filter { $0.scheduledAt >= day && $0.scheduledAt < next && $0.scheduledAt <= .now }
            let resolved = values.filter { $0.status.isTerminal }
            let done = resolved.filter { $0.status == .completed }
            let rate = resolved.isEmpty ? 0 : Double(done.count) / Double(resolved.count)
            return InsightDay(
                id: day,
                label: day.formatted(.dateTime.weekday(.abbreviated)),
                value: rate,
                hasData: !resolved.isEmpty
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(spacing: 16) {
                        Picker("Time period", selection: $period) {
                            ForEach(InsightPeriod.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        if occurrences.isEmpty {
                            emptyState
                        } else {
                            completionCard
                            trendCard
                            streakCard
                            routineProgressCard
                        }

                        Label(
                            "Silencing, dismissing, or snoozing is not completion—only an explicit completion action counts.",
                            systemImage: "info.circle.fill"
                        )
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.blue)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(JomadoTheme.sky.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(18)
                }
            }
            .jomadoPageBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()
            VStack(alignment: .leading, spacing: 7) {
                JomadoBrandWordmark()
                Text("Your\nProgress")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("Little steps add up to a\nhappier, healthier you.")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: completed.isEmpty ? .hopeful : .proud,
                cue: .idleFloat,
                accessibilityLabel: completed.isEmpty ? "Momo looks hopeful" : "Momo looks proud of your progress"
            )
            .frame(width: 176, height: 176)
            .offset(x: 86, y: 62)

            JomadoSpeechBubble(text: completed.isEmpty ? "Your first win will show up here!" : "Keep stacking small wins! 💙")
                .frame(maxWidth: 150)
                .offset(x: 28, y: 58)
        }
        .frame(height: 270)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            MomoArtwork(expression: .hopeful)
                .frame(width: 92, height: 92)
            Text("No data yet")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text("Complete a few reminders and your progress will appear here.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .jomadoCard()
    }

    private var completionCard: some View {
        HStack(spacing: 20) {
            JomadoProgressRing(
                progress: completionRate,
                color: JomadoTheme.cyan,
                label: "\(Int((completionRate * 100).rounded()))%",
                size: 112
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Completion")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(resolvedCount == 0
                     ? "No resolved reminders in this period yet."
                     : "\(completed.count) of \(resolvedCount) resolved reminders were completed.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)

                HStack(spacing: 8) {
                    insightMetric(value: "\(completed.count)", label: "Done", color: JomadoTheme.success)
                    insightMetric(value: "\(open.count)", label: "Open", color: JomadoTheme.blue)
                    insightMetric(value: "\(skipped.count + expired.count)", label: "Other", color: Color(jomadoHex: "FFB020"))
                }
            }
        }
        .jomadoCard()
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Trend")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text("Completion among resolved reminders each day")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(week) { day in
                    VStack(spacing: 6) {
                        Text(day.hasData ? "\(Int(day.value * 100))%" : "—")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(JomadoTheme.navy)
                        RoundedRectangle(cornerRadius: 7)
                            .fill(
                                LinearGradient(
                                    colors: [JomadoTheme.cyan, Color(jomadoHex: "2BD5D2")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(4, 118 * CGFloat(day.value)))
                            .opacity(day.hasData ? 1 : 0.18)
                        Text(day.label)
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(JomadoTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 158, alignment: .bottom)
        }
        .jomadoCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly completion trend")
    }

    private var streakCard: some View {
        HStack(spacing: 18) {
            JomadoIconBadge(symbol: "flame.fill", color: Color(jomadoHex: "FF8A2B"), size: 62)
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                Text("\(streaks.current) day\(streaks.current == 1 ? "" : "s")")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(streaks.current > 0 ? "Keep going!" : "Complete one to begin")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Divider().frame(height: 64)
            JomadoIconBadge(symbol: "flame", color: Color(jomadoHex: "A6B6CB"), size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("Best Streak")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.secondaryText)
                Text("\(streaks.best) day\(streaks.best == 1 ? "" : "s")")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
            }
        }
        .jomadoCard()
    }

    @ViewBuilder
    private var routineProgressCard: some View {
        let rows = routineProgressRows
        VStack(alignment: .leading, spacing: 14) {
            Text("Progress by Routine")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)

            if rows.isEmpty {
                Text("No resolved routine data in this period yet.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            } else {
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    routineProgress(
                        name: row.name,
                        detail: "\(row.completed) of \(row.resolved) resolved",
                        symbol: row.symbol,
                        value: row.rate,
                        color: row.color
                    )
                    if index < rows.count - 1 { Divider() }
                }
            }
        }
        .jomadoCard()
    }

    private var routineProgressRows: [RoutineProgressRow] {
        routines.compactMap { routine in
            let values = filteredOccurrences.filter { $0.routineID == routine.id }
            let resolved = values.filter { $0.status.isTerminal }
            guard !resolved.isEmpty else { return nil }
            let done = resolved.filter { $0.status == .completed }.count
            return RoutineProgressRow(
                id: routine.id,
                name: routine.name,
                symbol: routine.symbolName,
                color: Color(jomadoHex: routine.accentHex),
                completed: done,
                resolved: resolved.count,
                rate: Double(done) / Double(resolved.count)
            )
        }
        .sorted { $0.rate > $1.rate }
    }

    private var streaks: (current: Int, best: Int) {
        let completedDays = Set(completed.map { calendar.startOfDay(for: $0.completedAt ?? $0.scheduledAt) })
        guard !completedDays.isEmpty else { return (0, 0) }

        let sorted = completedDays.sorted()
        var best = 1
        var run = 1
        for index in 1..<sorted.count {
            let previous = sorted[index - 1]
            let current = sorted[index]
            let delta = calendar.dateComponents([.day], from: previous, to: current).day ?? 0
            if delta == 1 {
                run += 1
                best = max(best, run)
            } else if delta > 1 {
                run = 1
            }
        }

        let today = calendar.startOfDay(for: .now)
        let startDay: Date
        if completedDays.contains(today) {
            startDay = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), completedDays.contains(yesterday) {
            startDay = yesterday
        } else {
            return (0, best)
        }

        var currentStreak = 0
        var cursor = startDay
        while completedDays.contains(cursor) {
            currentStreak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return (currentStreak, best)
    }

    private func insightMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private func routineProgress(name: String, detail: String, symbol: String, value: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            JomadoIconBadge(symbol: symbol, color: color, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                Text(detail)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Spacer()
            Text("\(Int((value * 100).rounded()))%")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.13))
                    Capsule().fill(color).frame(width: proxy.size.width * CGFloat(value))
                }
            }
            .frame(width: 82, height: 9)
        }
    }
}

private enum InsightPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case allTime

    var id: String { rawValue }
    var title: String {
        switch self {
        case .week: "This Week"
        case .month: "This Month"
        case .allTime: "All Time"
        }
    }
}

private struct InsightDay: Identifiable {
    let id: Date
    let label: String
    let value: Double
    let hasData: Bool
}

private struct RoutineProgressRow: Identifiable {
    let id: UUID
    let name: String
    let symbol: String
    let color: Color
    let completed: Int
    let resolved: Int
    let rate: Double
}

#Preview {
    InsightsView()
        .modelContainer(for: [RoutineEntity.self, ReminderOccurrenceEntity.self, ContentExposureEntity.self], inMemory: true)
}
