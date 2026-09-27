import SwiftData
import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @Query(sort: \RoutineEntity.createdAt) private var routines: [RoutineEntity]
    @State private var filter: RoutineFilter = .all
    @State private var isAddingRoutine = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 16) {
                        Picker("Routine filter", selection: $filter) {
                            ForEach(RoutineFilter.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Filter routines")

                        if filteredRoutines.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredRoutines) { routine in
                                    routineCard(routine)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .jomadoPageBackground()
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isAddingRoutine) {
                AddRoutineFlowView { draft in
                    Task { await model.saveRoutine(draft) }
                }
            }
            .task { await model.reconcileSchedules() }
        }
    }

    private var filteredRoutines: [RoutineEntity] {
        routines.filter { $0.archivedAt == nil && filter.includes($0) }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    JomadoBrandWordmark()
                    Text("Your\nRoutines")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(JomadoTheme.navy)
                    Text("Small habits. A happier,\nhealthier you.")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }

                Spacer()

                Button {
                    isAddingRoutine = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(JomadoTheme.cyan, in: Circle())
                        .shadow(color: JomadoTheme.cyan.opacity(0.3), radius: 10, y: 5)
                }
                .accessibilityLabel("Add routine")
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: .hello,
                cue: .gentleBounce,
                accessibilityLabel: "Momo cheers beside your routines"
            )
            .frame(width: 158, height: 158)
            .offset(x: 72, y: 86)
        }
        .frame(height: 278)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            MomoArtwork(expression: .hopeful)
                .frame(width: 104, height: 104)
            Text(filter == .all ? "No routines yet" : "No \(filter.title.lowercased()) routines")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text(filter == .all
                 ? "Create your first routine to start building healthier habits."
                 : "Change the filter or update one of your routines.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)
            if filter == .all {
                Button("Add Your First Routine") { isAddingRoutine = true }
                    .buttonStyle(JomadoPrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .jomadoCard()
    }

    private func routineCard(_ routine: RoutineEntity) -> some View {
        let accent = Color(jomadoHex: routine.accentHex)

        return HStack(spacing: 12) {
            NavigationLink {
                RoutineDetailView(routine: routine)
            } label: {
                HStack(spacing: 13) {
                    JomadoIconBadge(symbol: routine.symbolName, color: accent, size: 58)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(routine.name)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(JomadoTheme.navy)
                        Text(routineSubtitle(routine.routineType))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(JomadoTheme.secondaryText)
                            .lineLimit(1)
                        Label(scheduleDescription(routine.schedule), systemImage: "clock")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(JomadoTheme.navy.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 2)

            Toggle(
                "Enabled",
                isOn: Binding(
                    get: { routine.enabled },
                    set: { newValue in
                        routine.enabled = newValue
                        Task { await model.setRoutineEnabled(id: routine.id, enabled: newValue) }
                    }
                )
            )
            .labelsHidden()
            .tint(JomadoTheme.cyan)

            NavigationLink {
                RoutineDetailView(routine: routine)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(.body, weight: .bold))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .frame(width: 28, height: 44)
            }
            .accessibilityLabel("Open \(routine.name)")
        }
        .padding(15)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: JomadoTheme.navy.opacity(0.06), radius: 12, y: 6)
    }

    private func routineSubtitle(_ type: RoutineType) -> String {
        switch type {
        case .hydration: "Drink water and feel your best."
        case .exercise: "Get moving for a stronger you."
        case .stretching: "Loosen up and stay flexible."
        case .eyeCare: "Give your eyes a rest."
        case .posture: "Sit and stand better."
        case .breathing: "Take a moment to reset."
        case .meditation: "Find calm in your day."
        case .yoga: "Build balance and mobility."
        case .sleep: "Rest well for a brighter tomorrow."
        case .custom, .generic: "Keep a small promise to yourself."
        }
    }

    private func scheduleDescription(_ schedule: RoutineSchedule) -> String {
        switch schedule {
        case .interval(let start, let end, let minutes, let weekdays):
            return "\(timeLabel(start))–\(timeLabel(end)) • \(repeatLabel(minutes)) • \(dayLabel(weekdays))"
        case .fixed(let times, let weekdays):
            let values = times.sorted().map(timeLabel).joined(separator: ", ")
            return "\(values) • \(dayLabel(weekdays))"
        }
    }

    private func timeLabel(_ time: LocalTime) -> String {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        let date = Calendar.current.date(from: components) ?? .now
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

    private func dayLabel(_ days: Set<Weekday>) -> String {
        if days.count == Weekday.allCases.count { return "Daily" }
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        if days == weekdays { return "Weekdays" }
        return Weekday.allCases.filter(days.contains).map(\.shortName).joined(separator: ", ")
    }
}

private enum RoutineFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case paused

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func includes(_ routine: RoutineEntity) -> Bool {
        switch self {
        case .all: true
        case .active: routine.enabled
        case .paused: !routine.enabled
        }
    }
}

extension Weekday {
    var shortName: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }
}

#Preview {
    RoutinesView()
        .environmentObject(JomadoAppModel())
        .modelContainer(for: [RoutineEntity.self, ReminderOccurrenceEntity.self, ContentExposureEntity.self], inMemory: true)
}
