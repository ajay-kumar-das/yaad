import SwiftUI

struct AddRoutineFlowView: View {
    let onSave: (RoutineType) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var selectedType: RoutineType = .hydration
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 8)) ?? .now
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 22)) ?? .now
    @State private var repeatHours = 2
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var usesAlarm = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    if page == 0 { chooseRoutine } else { scheduleRoutine }
                }
            }
            .jomadoPageBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.light)
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()
            HStack {
                Button {
                    if page == 0 { dismiss() } else { page = 0 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .heavy))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.9), in: Circle())
                }
                .foregroundStyle(JomadoTheme.navy)
                JomadoBrandWordmark()
                Spacer()
                VStack(alignment: .trailing, spacing: 7) {
                    JomadoStepIndicator(current: page == 0 ? 1 : 3, total: 4)
                    Text(page == 0 ? "Step 1 of 4" : "Step 3 of 4")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(JomadoTheme.navy)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: page == 0 ? .hello : .cheeky,
                cue: page == 0 ? .wave : .gentleBounce,
                accessibilityLabel: "Momo helps create a routine"
            )
            .frame(width: 176, height: 176)
            .offset(x: -52, y: 62)

            JomadoSpeechBubble(text: page == 0 ? "Small habits make a big, happier you!" : "Almost there—let’s set the details.")
                .frame(maxWidth: 178)
                .offset(x: 94, y: 84)
        }
        .frame(height: 266)
    }

    private var chooseRoutine: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Add Routine")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("What habit would you like to build?")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(availableTypes, id: \.self) { type in
                    Button { selectedType = type } label: {
                        VStack(spacing: 8) {
                            JomadoIconBadge(symbol: type.symbolName, color: Color(jomadoHex: type.accentHex), size: 62)
                            Text(type.displayName)
                                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .foregroundStyle(JomadoTheme.navy)
                            Text(shortDescription(for: type))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(JomadoTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 132)
                        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .stroke(selectedType == type ? JomadoTheme.cyan : .clear, lineWidth: 1.8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { page = 1 }
            } label: {
                Label("Next", systemImage: "arrow.right")
            }
            .buttonStyle(JomadoPrimaryButtonStyle())
        }
        .padding(20)
    }

    private var scheduleRoutine: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Routine")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("Set your schedule and review before saving.")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            scheduleCard
            reminderStyleCard
            deliveryCard
            previewCard
            Button {
                onSave(selectedType)
                dismiss()
            } label: {
                Label("Save Routine", systemImage: "arrow.right")
            }
            .buttonStyle(JomadoPrimaryButtonStyle())
        }
        .padding(20)
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Schedule")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            scheduleTimeRow(title: "Start time", symbol: "clock.fill", selection: $startTime)
            Divider()
            scheduleTimeRow(title: "End time", symbol: "moon.fill", selection: $endTime)
            Divider()
            HStack {
                JomadoIconBadge(symbol: "arrow.triangle.2.circlepath", color: JomadoTheme.cyan, size: 42)
                Text("Repeat")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                Spacer()
                Picker("Repeat", selection: $repeatHours) {
                    ForEach([1, 2, 3, 4], id: \.self) { hours in
                        Text("Every \(hours) hour\(hours == 1 ? "" : "s")").tag(hours)
                    }
                }
                .pickerStyle(.menu)
                .tint(JomadoTheme.navy)
            }
            Text("Days")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            HStack(spacing: 6) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Button(day.shortName) {
                        if selectedDays.contains(day) { selectedDays.remove(day) } else { selectedDays.insert(day) }
                    }
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(selectedDays.contains(day) ? .white : JomadoTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(selectedDays.contains(day) ? JomadoTheme.cyan : JomadoTheme.sky.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .jomadoCard()
    }

    private var reminderStyleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder style")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            HStack(spacing: 10) {
                styleChoice(title: "Alarm + Companion", subtitle: "Sound + Momo", symbol: "bell.fill", selected: usesAlarm) { usesAlarm = true }
                styleChoice(title: "Companion only", subtitle: "Momo, no alarm", symbol: "face.smiling.fill", selected: !usesAlarm) { usesAlarm = false }
            }
        }
        .jomadoCard()
    }

    private var deliveryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery readiness")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            readinessRow(title: "Notifications", symbol: "bell.fill", status: "Check Settings", color: Color(jomadoHex: "FF4D5A"))
            readinessRow(title: "Live Activities", symbol: "iphone.gen3", status: "Available", color: Color(jomadoHex: "20C8B4"))
        }
        .jomadoCard()
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            JomadoIconBadge(symbol: selectedType.symbolName, color: Color(jomadoHex: selectedType.accentHex), size: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily \(selectedType.displayName)")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text("Every \(repeatHours) hour\(repeatHours == 1 ? "" : "s")  •  \(startTime.formatted(date: .omitted, time: .shortened))–\(endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .jomadoCard()
    }

    private func scheduleTimeRow(title: String, symbol: String, selection: Binding<Date>) -> some View {
        HStack {
            JomadoIconBadge(symbol: symbol, color: JomadoTheme.cyan, size: 42)
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.navy)
            Spacer()
            DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(JomadoTheme.cyan)
        }
    }

    private func styleChoice(title: String, subtitle: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(JomadoTheme.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(.caption, design: .rounded, weight: .heavy))
                    Text(subtitle).font(.system(.caption2, design: .rounded)).foregroundStyle(JomadoTheme.secondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? JomadoTheme.cyan : Color.gray.opacity(0.35))
            }
            .foregroundStyle(JomadoTheme.navy)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(selected ? JomadoTheme.sky.opacity(0.7) : .white, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? JomadoTheme.cyan : Color.gray.opacity(0.12), lineWidth: 1.2)
            }
        }
        .buttonStyle(.plain)
    }

    private func readinessRow(title: String, symbol: String, status: String, color: Color) -> some View {
        HStack {
            JomadoIconBadge(symbol: symbol, color: color, size: 42)
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.navy)
            Spacer()
            Text(status)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color.opacity(0.12), in: Capsule())
        }
    }

    private func shortDescription(for type: RoutineType) -> String {
        switch type {
        case .hydration: "Drink more water"
        case .exercise: "Move your body"
        case .stretching: "Feel looser"
        case .eyeCare: "Rest your eyes"
        case .posture: "Stand taller"
        case .breathing: "Feel calmer"
        case .meditation: "Be mindful"
        case .yoga: "Build balance"
        case .sleep: "Rest better"
        case .custom: "Your own routine"
        case .generic: "Build a habit"
        }
    }

    private var availableTypes: [RoutineType] {
        [.hydration, .exercise, .stretching, .eyeCare, .yoga, .posture, .breathing, .meditation, .sleep, .custom]
    }
}

private extension Weekday {
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
    AddRoutineFlowView(onSave: { _ in })
}
