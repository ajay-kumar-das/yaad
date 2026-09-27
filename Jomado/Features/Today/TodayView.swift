import SwiftData
import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @Query(sort: \RoutineEntity.createdAt) private var routines: [RoutineEntity]
    @Query(sort: \ReminderOccurrenceEntity.scheduledAt) private var occurrences: [ReminderOccurrenceEntity]

    private var calendar: Calendar { .current }
    private var startOfToday: Date { calendar.startOfDay(for: .now) }
    private var startOfTomorrow: Date {
        calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86_400)
    }

    private var activeRoutines: [RoutineEntity] { routines.filter(\.enabled) }
    private var todayOccurrences: [ReminderOccurrenceEntity] {
        occurrences.filter { $0.scheduledAt >= startOfToday && $0.scheduledAt < startOfTomorrow }
    }
    private var completedToday: Int { todayOccurrences.filter { $0.status == .completed }.count }
    private var totalToday: Int { todayOccurrences.count }
    private var progress: Double {
        guard totalToday > 0 else { return 0 }
        return Double(completedToday) / Double(totalToday)
    }
    private var progressPercent: Int { Int((progress * 100).rounded()) }

    private var nextOccurrence: ReminderOccurrenceEntity? {
        let unresolved = occurrences.filter { !$0.status.isTerminal }
        let today = unresolved.filter {
            $0.scheduledAt >= startOfToday && $0.scheduledAt < startOfTomorrow
        }
        if let earliestToday = today.min(by: { $0.scheduledAt < $1.scheduledAt }) {
            return earliestToday
        }
        return unresolved
            .filter { $0.scheduledAt >= startOfTomorrow }
            .min(by: { $0.scheduledAt < $1.scheduledAt })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 16) {
                        progressCard
                        nextUpCard
                        quickActions
                        routineList

                        #if DEBUG
                        previewTools
                        #endif
                    }
                    .padding(18)
                }
            }
            .jomadoPageBackground()
            .toolbar(.hidden, for: .navigationBar)
            .task { await model.reconcileSchedules() }
        }
    }

    private var hero: some View {
        let hasCompletedSomething = completedToday > 0

        return ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    JomadoBrandWordmark()
                    Spacer()
                    Image(systemName: "bell")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(JomadoTheme.navy)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.88), in: Circle())
                        .accessibilityLabel("Notifications")
                }

                Spacer()

                Text(hasCompletedSomething ? "Nice work today!" : greeting)
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("A healthier, happier\nyou is in the making. 💙")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)

            AnimatedMomoView(
                expression: hasCompletedSomething ? .proud : .hello,
                cue: hasCompletedSomething ? .celebrate : .idleFloat,
                accessibilityLabel: hasCompletedSomething ? "Momo looks proud" : "Momo waves hello"
            )
            .frame(width: 188, height: 188)
            .offset(x: 78, y: 64)

            JomadoSpeechBubble(text: hasCompletedSomething ? "Keep that momentum! 💙" : "One small step at a time! 💙")
                .frame(maxWidth: 150)
                .offset(x: 104, y: 62)
        }
        .frame(height: 304)
    }

    private var progressCard: some View {
        HStack(spacing: 18) {
            JomadoProgressRing(
                progress: progress,
                color: JomadoTheme.cyan,
                label: "\(progressPercent)%",
                size: 108
            )

            VStack(alignment: .leading, spacing: 7) {
                Text("Today’s Progress")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(totalToday == 0
                     ? "No scheduled occurrences today"
                     : "\(completedToday) of \(totalToday) reminders completed")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)

                Label(progressStatusText, systemImage: progressStatusSymbol)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(progressStatusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(progressStatusColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            Spacer(minLength: 0)
        }
        .jomadoCard()
    }

    @ViewBuilder
    private var nextUpCard: some View {
        if let occurrence = nextOccurrence, let routine = routine(for: occurrence.routineID) {
            Button {
                Task {
                    await model.openOccurrence(
                        occurrenceID: occurrence.id,
                        routineID: occurrence.routineID
                    )
                }
            } label: {
                HStack(spacing: 13) {
                    JomadoIconBadge(
                        symbol: occurrence.scheduledAt <= .now ? "bell.badge.fill" : "bell.fill",
                        color: occurrence.scheduledAt <= .now ? Color(jomadoHex: "FF8A2B") : Color(jomadoHex: "FFB020"),
                        size: 52
                    )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(occurrence.scheduledAt <= .now ? "Needs attention" : "Next up")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(JomadoTheme.secondaryText)
                        Text(routine.name)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(JomadoTheme.navy)
                        Text(nextTimeText(occurrence.scheduledAt))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(JomadoTheme.secondaryText)
                    }
                    Spacer()
                    MomoArtwork(expression: occurrence.scheduledAt <= .now ? .concerned : .hopeful)
                        .frame(width: 46, height: 46)
                    Label("View", systemImage: "chevron.right")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(JomadoTheme.blue)
                }
                .padding(15)
                .background(JomadoTheme.sky.opacity(0.78), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 13) {
                JomadoIconBadge(symbol: "checkmark.circle.fill", color: JomadoTheme.success, size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(activeRoutines.isEmpty ? "No routines yet" : "All clear")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(JomadoTheme.secondaryText)
                    Text(activeRoutines.isEmpty ? "Create your first routine" : "No unresolved reminders")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                    Text(activeRoutines.isEmpty ? "Use the Routines tab to get started." : "Momo will be ready for the next one.")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }
                Spacer()
                MomoArtwork(expression: .proud)
                    .frame(width: 46, height: 46)
            }
            .padding(15)
            .background(JomadoTheme.sky.opacity(0.78), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var quickActions: some View {
        HStack(spacing: 9) {
            quickAction(title: "Log Water", symbol: "drop.fill", color: JomadoTheme.cyan) {
                openNext(type: .hydration)
            }
            quickAction(title: "Start Stretch", symbol: "figure.flexibility", color: Color(jomadoHex: "7C5CFC")) {
                openNext(type: .stretching)
            }
            quickAction(title: "View Progress", symbol: "chart.bar.fill", color: Color(jomadoHex: "20C985")) {
                model.selectedTab = .insights
            }
            quickAction(title: "Get a Nudge", symbol: "face.smiling.fill", color: Color(jomadoHex: "FFB020")) {
                guard let occurrence = nextOccurrence else { return }
                Task { await model.openOccurrence(occurrenceID: occurrence.id, routineID: occurrence.routineID) }
            }
        }
    }

    @ViewBuilder
    private var routineList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today’s Routines")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Spacer()
                Text("\(activeRoutines.count) active")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.blue)
            }

            if activeRoutines.isEmpty {
                Text("Add a routine to start scheduling reminders.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .jomadoCard()
            } else {
                ForEach(activeRoutines.prefix(4)) { routine in
                    let routineOccurrences = todayOccurrences.filter { $0.routineID == routine.id }
                    let completed = routineOccurrences.filter { $0.status == .completed }.count
                    let total = routineOccurrences.count
                    routineSummary(
                        routine: routine,
                        detail: scheduleDescription(routine.schedule),
                        progress: "\(completed) / \(total)",
                        value: total == 0 ? 0 : Double(completed) / Double(total)
                    )
                }
            }
        }
    }

    private func quickAction(title: String, symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                JomadoIconBadge(symbol: symbol, color: color, size: 42)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 86)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func routineSummary(routine: RoutineEntity, detail: String, progress: String, value: Double) -> some View {
        HStack(spacing: 12) {
            JomadoIconBadge(symbol: routine.symbolName, color: Color(jomadoHex: routine.accentHex), size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(routine.name)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(detail)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Text(progress)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            ZStack {
                Circle().stroke(JomadoTheme.sky, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(Color(jomadoHex: routine.accentHex), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 38, height: 38)
        }
        .padding(13)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var greeting: String {
        switch calendar.component(.hour, from: .now) {
        case 5..<12: "Good morning!"
        case 12..<17: "Good afternoon!"
        case 17..<22: "Good evening!"
        default: "Hello there!"
        }
    }

    private var progressStatusText: String {
        if totalToday == 0 { return activeRoutines.isEmpty ? "Add a routine" : "Schedule is clear" }
        if completedToday == totalToday { return "All done for today!" }
        if progress >= 0.5 { return "You’re making progress!" }
        return "One small step next"
    }

    private var progressStatusSymbol: String {
        completedToday == totalToday && totalToday > 0 ? "checkmark" : "arrow.up.right"
    }

    private var progressStatusColor: Color {
        completedToday == totalToday && totalToday > 0 ? JomadoTheme.success : JomadoTheme.cyan
    }

    private func routine(for id: UUID) -> RoutineEntity? {
        routines.first { $0.id == id }
    }

    private func openNext(type: RoutineType) {
        guard let routine = activeRoutines.first(where: { $0.routineType == type }) else { return }
        guard let occurrence = occurrences
            .filter({
                $0.routineID == routine.id
                    && !$0.status.isTerminal
                    && $0.scheduledAt >= startOfToday
            })
            .min(by: { $0.scheduledAt < $1.scheduledAt }) else { return }
        Task { await model.openOccurrence(occurrenceID: occurrence.id, routineID: occurrence.routineID) }
    }

    private func nextTimeText(_ date: Date) -> String {
        let absolute = date.formatted(date: calendar.isDateInToday(date) ? .omitted : .abbreviated, time: .shortened)
        let interval = date.timeIntervalSinceNow
        if abs(interval) < 60 { return "Due now • \(absolute)" }
        if interval < 0 {
            let minutes = max(1, Int(abs(interval) / 60))
            return "\(minutes)m overdue • \(absolute)"
        }
        if interval < 3_600 {
            return "In \(max(1, Int(interval / 60))) min • \(absolute)"
        }
        return absolute
    }

    private func scheduleDescription(_ schedule: RoutineSchedule) -> String {
        switch schedule {
        case .interval(let start, let end, let minutes, _):
            return "\(timeLabel(start))–\(timeLabel(end)) • \(repeatLabel(minutes))"
        case .fixed(let times, _):
            return times.sorted().map(timeLabel).joined(separator: ", ")
        }
    }

    private func timeLabel(_ time: LocalTime) -> String {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        let date = calendar.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func repeatLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "Every \(minutes) min" }
        if minutes % 60 == 0 {
            let hours = minutes / 60
            return "Every \(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "Every \(minutes / 60)h \(minutes % 60)m"
    }

    #if DEBUG
    private var previewTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System surface preview")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text("Visible only in Debug builds. Test these on a physical iPhone.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
            HStack {
                Button("Start Live Activity") { Task { await model.startLiveActivity() } }
                    .buttonStyle(.borderedProminent)
                Button("Reset") { Task { await model.resetPreview() } }
                    .buttonStyle(.bordered)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ReminderUrgencyStage.allCases, id: \.self) { stage in
                        Button(stage.label) { Task { await model.preview(stage: stage) } }
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .buttonStyle(.bordered)
                            .tint(Color(jomadoHex: stage.accentHex))
                    }
                }
            }
            if let message = model.systemMessage {
                Text(message)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
        }
        .tint(JomadoTheme.cyan)
        .jomadoCard()
    }
    #endif
}

#Preview {
    TodayView()
        .environmentObject(JomadoAppModel())
        .modelContainer(for: [RoutineEntity.self, ReminderOccurrenceEntity.self, ContentExposureEntity.self], inMemory: true)
}
