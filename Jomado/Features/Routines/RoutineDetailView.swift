import SwiftData
import SwiftUI

struct RoutineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: JomadoAppModel
    @Bindable var routine: RoutineEntity

    @State private var isEditing = false
    @State private var showsDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero

                VStack(spacing: 16) {
                    statusCard
                    scheduleCard
                    companionCard
                    completionCard
                    actionsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
        }
        .jomadoPageBackground()
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $isEditing) {
            AddRoutineFlowView(initialRoutine: routine.instance) { draft in
                Task { await model.updateRoutine(id: routine.id, draft: draft) }
            }
        }
        .confirmationDialog(
            "Delete \(routine.name)?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Routine", role: .destructive) {
                let routineID = routine.id
                dismiss()
                Task { await model.deleteRoutine(id: routineID) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Future reminders will stop. Completed and resolved history is kept for your Insights unless you explicitly remove app data.")
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            HStack {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.92), in: Circle())
                }
                .accessibilityLabel("Back to routines")

                JomadoBrandWordmark()
                Spacer()

                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(JomadoTheme.cyan, in: Circle())
                        .shadow(color: JomadoTheme.cyan.opacity(0.28), radius: 10, y: 5)
                }
                .accessibilityLabel("Edit routine")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(routine.name)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                    .lineLimit(2)
                Text(routineSubtitle)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: 215, alignment: .leading)
            .offset(x: -58, y: 88)

            AnimatedMomoView(
                expression: routine.enabled ? .hello : .hopeful,
                cue: routine.enabled ? .gentleBounce : .idleFloat,
                accessibilityLabel: "Momo beside \(routine.name)"
            )
            .frame(width: 150, height: 150)
            .offset(x: 96, y: 84)
        }
        .frame(height: 270)
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            JomadoIconBadge(
                symbol: routine.symbolName,
                color: Color(jomadoHex: routine.accentHex),
                size: 62
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(routine.enabled ? "Routine active" : "Routine paused")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(routine.enabled
                     ? "Jomado will keep this routine in the delivery schedule."
                     : "No new reminders are scheduled while this routine is paused.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }

            Spacer(minLength: 8)

            Toggle(
                "Routine active",
                isOn: Binding(
                    get: { routine.enabled },
                    set: { enabled in
                        routine.enabled = enabled
                        Task { await model.setRoutineEnabled(id: routine.id, enabled: enabled) }
                    }
                )
            )
            .labelsHidden()
            .tint(JomadoTheme.cyan)
        }
        .jomadoCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Schedule", symbol: "clock.fill")
            detailRow("Pattern", value: scheduleDescription(routine.schedule))
            detailRow("Days", value: dayDescription(routine.schedule))
            detailRow("Delivery", value: routine.deliveryMode == .alarmAndCompanion ? "Alarm + Companion" : "Companion only")

            Button {
                isEditing = true
            } label: {
                Label("Edit schedule", systemImage: "calendar.badge.clock")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .foregroundStyle(JomadoTheme.blue)
            .background(JomadoTheme.sky.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
        }
        .jomadoCard()
    }

    private var companionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Momo & reminder style", symbol: "face.smiling.fill")
            detailRow("Personality", value: routine.personality.displayName)
            detailRow("Intensity", value: routine.intensity.displayName)
            detailRow(
                "Smart snooze",
                value: routine.smartSnoozeEnabled
                    ? "\(routine.snoozeMinutes) min • up to \(routine.maxSnoozes)"
                    : "Off"
            )
            detailRow("Helpful tips", value: routine.contentTipEnabled ? "On" : "Off")
            if let goal = routine.goal, !goal.isEmpty {
                detailRow("Goal", value: goal)
            }
        }
        .jomadoCard()
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Completion", symbol: "checkmark.circle.fill")
            Text("Only an explicit completion action counts this routine as done.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
            HStack {
                Text("Action label")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                Spacer()
                Text(routine.completionLabel)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.blue)
            }
        }
        .jomadoCard()
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button {
                isEditing = true
            } label: {
                Label("Edit Routine", systemImage: "pencil")
            }
            .buttonStyle(JomadoPrimaryButtonStyle())

            Button(role: .destructive) {
                showsDeleteConfirmation = true
            } label: {
                Label("Delete Routine", systemImage: "trash")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
        }
        .padding(.top, 4)
    }

    private func sectionHeader(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(.title3, design: .rounded, weight: .heavy))
            .foregroundStyle(JomadoTheme.navy)
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.secondaryText)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.navy)
                .multilineTextAlignment(.trailing)
        }
    }

    private var routineSubtitle: String {
        switch routine.routineType {
        case .hydration: "Drink water and feel your best."
        case .exercise: "Get moving for a stronger you."
        case .stretching: "Loosen up and stay flexible."
        case .eyeCare: "Give your eyes a proper break."
        case .posture: "Reset your posture through the day."
        case .breathing: "Take a moment to reset."
        case .meditation: "Find calm in your day."
        case .yoga: "Create space for balance and movement."
        case .sleep: "Rest well for a brighter tomorrow."
        case .custom, .generic: "A small routine worth keeping."
        }
    }

    private func scheduleDescription(_ schedule: RoutineSchedule) -> String {
        switch schedule {
        case .interval(let start, let end, let minutes, _):
            return "\(timeLabel(start))–\(timeLabel(end)) • \(repeatLabel(minutes))"
        case .fixed(let times, _):
            return times.sorted().map(timeLabel).joined(separator: ", ")
        }
    }

    private func dayDescription(_ schedule: RoutineSchedule) -> String {
        let days: Set<Weekday>
        switch schedule {
        case .interval(_, _, _, let weekdays), .fixed(_, let weekdays):
            days = weekdays
        }
        if days.count == Weekday.allCases.count { return "Daily" }
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        if days == weekdays { return "Weekdays" }
        return Weekday.allCases.filter(days.contains).map(\.shortName).joined(separator: ", ")
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
}
