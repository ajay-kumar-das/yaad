import SwiftUI

struct AddRoutineFlowView: View {
    let onSave: (RoutineDraft) -> Void
    private let isEditing: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var selectedType: RoutineType = .hydration
    @State private var scheduleMode: RoutineScheduleMode = .interval
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 8)) ?? .now
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 22)) ?? .now
    @State private var repeatMinutes = 120
    @State private var fixedTimes: [Date] = [
        Calendar.current.date(from: DateComponents(hour: 8)) ?? .now
    ]
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    @State private var usesAlarm = true
    @State private var routineName = RoutineType.hydration.displayName
    @State private var completionLabel = RoutineType.hydration.defaultCompletionLabel
    @State private var selectedSymbol = RoutineType.hydration.symbolName
    @State private var selectedAccent = RoutineType.hydration.accentHex
    @State private var personality: ReminderPersonality = .playful
    @State private var intensity: ReminderIntensity = .balanced
    @State private var smartSnoozeEnabled = true
    @State private var snoozeMinutes = 10
    @State private var maxSnoozes = 3
    @State private var goal = ""
    @State private var contentTipEnabled = true
    @State private var validationMessage: String?

    @AppStorage("jomado.defaultPersonality") private var defaultPersonalityRaw = ReminderPersonality.playful.rawValue
    @AppStorage("jomado.defaultIntensity") private var defaultIntensityRaw = ReminderIntensity.balanced.rawValue

    init(
        initialRoutine: RoutineInstance? = nil,
        onSave: @escaping (RoutineDraft) -> Void
    ) {
        self.onSave = onSave
        isEditing = initialRoutine != nil

        guard let routine = initialRoutine else { return }

        func date(for time: LocalTime) -> Date {
            Calendar.current.date(
                from: DateComponents(hour: time.hour, minute: time.minute)
            ) ?? .now
        }

        _page = State(initialValue: 1)
        _selectedType = State(initialValue: routine.type)
        _usesAlarm = State(initialValue: routine.deliveryMode == .alarmAndCompanion)
        _routineName = State(initialValue: routine.name)
        _completionLabel = State(initialValue: routine.completionLabel)
        _selectedSymbol = State(initialValue: routine.symbolName)
        _selectedAccent = State(initialValue: routine.accentHex)
        _personality = State(initialValue: routine.personality)
        _intensity = State(initialValue: routine.intensity)
        _smartSnoozeEnabled = State(initialValue: routine.smartSnoozeEnabled)
        _snoozeMinutes = State(initialValue: routine.snoozeMinutes)
        _maxSnoozes = State(initialValue: routine.maxSnoozes)
        _goal = State(initialValue: routine.goal ?? "")
        _contentTipEnabled = State(initialValue: routine.contentTipEnabled)

        switch routine.schedule {
        case .interval(let start, let end, let everyMinutes, let weekdays):
            _scheduleMode = State(initialValue: .interval)
            _startTime = State(initialValue: date(for: start))
            _endTime = State(initialValue: date(for: end))
            _repeatMinutes = State(initialValue: everyMinutes)
            _selectedDays = State(initialValue: weekdays)
        case .fixed(let times, let weekdays):
            _scheduleMode = State(initialValue: .fixedTimes)
            _fixedTimes = State(initialValue: times.sorted().map(date(for:)))
            _selectedDays = State(initialValue: weekdays)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    currentPage
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 34)
                }
            }
            .jomadoPageBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.light)
        .onAppear {
            guard !isEditing else { return }
            personality = ReminderPersonality(rawValue: defaultPersonalityRaw) ?? .playful
            intensity = ReminderIntensity(rawValue: defaultIntensityRaw) ?? .balanced
            applyDefaults(for: selectedType)
        }
        .onChange(of: selectedType) { _, newType in
            applyDefaults(for: newType)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: page)
    }

    @ViewBuilder
    private var currentPage: some View {
        switch page {
        case 0: chooseRoutine
        case 1: scheduleRoutine
        case 2: customizeRoutine
        default: reviewRoutine
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            HStack {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .heavy))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.9), in: Circle())
                }
                .foregroundStyle(JomadoTheme.navy)
                .accessibilityLabel(page == 0 ? "Close" : "Previous step")

                JomadoBrandWordmark()
                Spacer()

                VStack(alignment: .trailing, spacing: 7) {
                    JomadoStepIndicator(current: page + 1, total: 4)
                    Text("Step \(page + 1) of 4")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(JomadoTheme.navy)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: heroExpression,
                cue: page == 3 ? .celebrate : (page == 0 ? .wave : .gentleBounce),
                accessibilityLabel: "Momo helps create a routine"
            )
            .frame(width: 184, height: 184)
            .offset(x: -52, y: 60)

            JomadoSpeechBubble(text: heroMessage)
                .frame(maxWidth: 188)
                .offset(x: 96, y: 86)
        }
        .frame(height: 278)
    }

    private var heroExpression: MascotExpression {
        switch page {
        case 0: .hello
        case 1: .cheeky
        case 2: .focused
        default: .celebrating
        }
    }

    private var heroMessage: String {
        switch page {
        case 0: "Small habits make a big, happier you! 💙"
        case 1: "Let’s choose when I should show up."
        case 2: "Make this routine feel like yours!"
        default: "Almost there — everything look right?"
        }
    }

    private var chooseRoutine: some View {
        VStack(alignment: .leading, spacing: 18) {
            pageHeading(
                title: isEditing ? "Change routine type" : "Add Routine",
                subtitle: "What habit would you like to build?"
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                ForEach(availableTypes, id: \.self) { type in
                    Button { selectedType = type } label: {
                        VStack(spacing: 8) {
                            JomadoIconBadge(
                                symbol: type.symbolName,
                                color: Color(jomadoHex: type.accentHex),
                                size: 66
                            )
                            Text(type.displayName)
                                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .foregroundStyle(JomadoTheme.navy)
                                .lineLimit(1)
                            Text(shortDescription(for: type))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(JomadoTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 134)
                        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(selectedType == type ? JomadoTheme.cyan : Color.clear, lineWidth: 1.8)
                        }
                        .shadow(color: JomadoTheme.navy.opacity(0.05), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(type.displayName), \(shortDescription(for: type))")
                    .accessibilityAddTraits(selectedType == type ? .isSelected : [])
                }
            }

            primaryNextButton(title: "Next") {
                validationMessage = nil
                page = 1
            }
        }
    }

    private var scheduleRoutine: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageHeading(
                title: "Set your schedule",
                subtitle: "Choose when and how often Momo should remind you."
            )

            scheduleModeCard

            if scheduleMode == .interval {
                intervalScheduleCard
            } else {
                fixedTimesCard
            }

            daysCard
            reminderStyleCard

            validationText

            primaryNextButton(title: "Next") {
                guard validateSchedule() else { return }
                page = 2
            }
        }
    }

    private var scheduleModeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Schedule type", subtitle: "Pick the pattern that matches this habit.")
            Picker("Schedule type", selection: $scheduleMode) {
                ForEach(RoutineScheduleMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .jomadoCard()
    }

    private var intervalScheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Window + interval", subtitle: "Repeat inside a daily time window.")
            scheduleTimeRow(title: "Start time", subtitle: "When reminders begin", symbol: "clock.fill", selection: $startTime)
            Divider()
            scheduleTimeRow(title: "End time", subtitle: "When reminders stop", symbol: "moon.fill", selection: $endTime)
            Divider()
            HStack(spacing: 12) {
                JomadoIconBadge(symbol: "arrow.triangle.2.circlepath", color: JomadoTheme.cyan, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repeat")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(JomadoTheme.navy)
                    Text("How often to remind you")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }
                Spacer()
                Picker("Repeat", selection: $repeatMinutes) {
                    ForEach([20, 30, 45, 60, 90, 120, 180, 240], id: \.self) { minutes in
                        Text(repeatLabel(minutes)).tag(minutes)
                    }
                }
                .pickerStyle(.menu)
                .tint(JomadoTheme.navy)
            }

            if LocalTime(date: endTime) < LocalTime(date: startTime) {
                Label("This window continues past midnight.", systemImage: "moon.stars.fill")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(JomadoTheme.blue)
            }
        }
        .jomadoCard()
    }

    private var fixedTimesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Fixed times", subtitle: "Choose one or more exact reminder times.")

            ForEach(fixedTimes.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    JomadoIconBadge(symbol: "clock.fill", color: JomadoTheme.cyan, size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time \(index + 1)")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(JomadoTheme.navy)
                        Text("A reminder fires at this local time")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(JomadoTheme.secondaryText)
                    }
                    Spacer()
                    DatePicker(
                        "Time \(index + 1)",
                        selection: Binding(
                            get: { fixedTimes[index] },
                            set: { fixedTimes[index] = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(JomadoTheme.cyan)

                    if fixedTimes.count > 1 {
                        Button(role: .destructive) {
                            fixedTimes.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .accessibilityLabel("Remove time \(index + 1)")
                    }
                }

                if index < fixedTimes.count - 1 { Divider() }
            }

            if fixedTimes.count < 6 {
                Button {
                    let base = fixedTimes.last ?? .now
                    fixedTimes.append(base.addingTimeInterval(2 * 60 * 60))
                } label: {
                    Label("Add another time", systemImage: "plus.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .foregroundStyle(JomadoTheme.blue)
            }
        }
        .jomadoCard()
    }

    private var daysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Days", subtitle: "Select which days to include.")
            HStack(spacing: 6) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Button(day.shortName) {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(selectedDays.contains(day) ? .white : JomadoTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        selectedDays.contains(day) ? JomadoTheme.cyan : JomadoTheme.sky.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .accessibilityAddTraits(selectedDays.contains(day) ? .isSelected : [])
                }
            }
        }
        .jomadoCard()
    }

    private var reminderStyleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Reminder style", subtitle: "Choose how you’d like to be reminded.")
            HStack(spacing: 10) {
                styleChoice(
                    title: "Alarm + Companion",
                    subtitle: "Sound + Momo appears",
                    symbol: "bell.fill",
                    selected: usesAlarm
                ) { usesAlarm = true }
                styleChoice(
                    title: "Companion only",
                    subtitle: "Momo only, no alarm",
                    symbol: "face.smiling.fill",
                    selected: !usesAlarm
                ) { usesAlarm = false }
            }
        }
        .jomadoCard()
    }

    private var customizeRoutine: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageHeading(
                title: "Make it yours",
                subtitle: "Customize the routine, Momo’s tone, and what counts as done."
            )

            routineDetailsCard
            appearanceCard
            personalityCard
            snoozeCard
            coachingCard

            validationText

            primaryNextButton(title: "Review") {
                guard validateCustomization() else { return }
                page = 3
            }
        }
    }

    private var routineDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Routine details", subtitle: "Use labels that feel natural to you.")

            labeledTextField("Routine name", text: $routineName, prompt: selectedType.displayName)
            labeledTextField("Completion label", text: $completionLabel, prompt: selectedType.defaultCompletionLabel)
        }
        .jomadoCard()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Icon & color", subtitle: "Choose how this routine appears across Jomado.")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(symbolOptions, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(selectedSymbol == symbol ? .white : Color(jomadoHex: selectedAccent))
                                .frame(width: 48, height: 48)
                                .background(
                                    selectedSymbol == symbol ? Color(jomadoHex: selectedAccent) : Color(jomadoHex: selectedAccent).opacity(0.1),
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Use \(symbol) icon")
                        .accessibilityAddTraits(selectedSymbol == symbol ? .isSelected : [])
                    }
                }
            }

            HStack(spacing: 12) {
                ForEach(accentOptions, id: \.self) { hex in
                    Button {
                        selectedAccent = hex
                    } label: {
                        Circle()
                            .fill(Color(jomadoHex: hex))
                            .frame(width: 38, height: 38)
                            .overlay {
                                if selectedAccent == hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .padding(3)
                                    .opacity(selectedAccent == hex ? 1 : 0)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Choose routine color")
                    .accessibilityAddTraits(selectedAccent == hex ? .isSelected : [])
                }
            }
        }
        .jomadoCard()
    }

    private var personalityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Companion personality", subtitle: "Momo can sound different for each routine.")

            HStack(spacing: 12) {
                MomoArtwork(expression: personality == .dramatic ? .dramatic : (personality == .strict ? .focused : .hello))
                    .frame(width: 70, height: 70)

                VStack(alignment: .leading, spacing: 8) {
                    Picker("Personality", selection: $personality) {
                        ForEach(ReminderPersonality.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(JomadoTheme.navy)

                    Text("Mascot: Momo")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }
                Spacer()
            }

            Picker("Intensity", selection: $intensity) {
                ForEach(ReminderIntensity.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .jomadoCard()
    }

    private var snoozeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $smartSnoozeEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Smart snooze")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                    Text("Allow a limited number of follow-up reminders without marking the routine done.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }
            }
            .tint(JomadoTheme.cyan)

            if smartSnoozeEnabled {
                Divider()
                Stepper(value: $snoozeMinutes, in: 5...30, step: 5) {
                    settingValueRow("Snooze length", value: "\(snoozeMinutes) min")
                }
                Stepper(value: $maxSnoozes, in: 1...5) {
                    settingValueRow("Maximum snoozes", value: "\(maxSnoozes)")
                }
            }
        }
        .jomadoCard()
    }

    private var coachingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Goal & coaching", subtitle: "Optional context helps the routine feel purposeful.")
            labeledTextField("Goal", text: $goal, prompt: goalPrompt(for: selectedType))
            Toggle("Show helpful tips in reminders", isOn: $contentTipEnabled)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.navy)
                .tint(JomadoTheme.cyan)
        }
        .jomadoCard()
    }

    private var reviewRoutine: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageHeading(
                title: isEditing ? "Review your changes" : "Review your routine",
                subtitle: isEditing
                    ? "Confirm the updated routine before Jomado refreshes its schedule."
                    : "One last check before Jomado starts scheduling reminders."
            )

            previewCard
            reviewScheduleCard
            reviewCustomizationCard
            deliveryCard

            validationText

            Button {
                saveRoutine()
            } label: {
                Label(isEditing ? "Save Changes" : "Save Routine", systemImage: "arrow.right")
            }
            .buttonStyle(JomadoPrimaryButtonStyle())
        }
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            JomadoIconBadge(
                symbol: selectedSymbol,
                color: Color(jomadoHex: selectedAccent),
                size: 62
            )
            VStack(alignment: .leading, spacing: 5) {
                Text(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedType.displayName : routineName)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(scheduleSummary)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .lineLimit(2)
                Text(daySummary)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.blue)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(JomadoTheme.success)
        }
        .jomadoCard()
    }

    private var reviewScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Schedule", subtitle: "When Jomado will create occurrences.")
            reviewLine(symbol: scheduleMode == .interval ? "arrow.triangle.2.circlepath" : "clock.fill", title: scheduleMode.title, value: scheduleSummary)
            reviewLine(symbol: "calendar", title: "Days", value: daySummary)
            reviewLine(symbol: usesAlarm ? "alarm.fill" : "face.smiling.fill", title: "Delivery", value: usesAlarm ? "Alarm + Companion" : "Companion only")
        }
        .jomadoCard()
    }

    private var reviewCustomizationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Companion & completion", subtitle: "How this routine behaves.")
            reviewLine(symbol: "face.smiling.fill", title: "Personality", value: "\(personality.displayName) • \(intensity.displayName)")
            reviewLine(symbol: "checkmark.circle.fill", title: "Complete with", value: completionLabel)
            reviewLine(
                symbol: "clock.arrow.circlepath",
                title: "Smart snooze",
                value: smartSnoozeEnabled ? "\(snoozeMinutes) min • up to \(maxSnoozes)" : "Off"
            )
            if !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                reviewLine(symbol: "target", title: "Goal", value: goal)
            }
        }
        .jomadoCard()
    }

    private var deliveryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Delivery readiness", subtitle: "Permissions can be changed later without losing the routine.")
            readinessRow(title: "Notifications", symbol: "bell.fill", status: "Managed by iOS", color: JomadoTheme.cyan)
            if usesAlarm {
                readinessRow(title: "Alarm access", symbol: "alarm.fill", status: "Requested if needed", color: Color(jomadoHex: "FFB020"))
            }
            readinessRow(title: "Live Activities", symbol: "iphone.gen3", status: "Used when available", color: Color(jomadoHex: "20C8B4"))
        }
        .jomadoCard()
    }

    @ViewBuilder
    private var validationText: some View {
        if let validationMessage {
            Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(jomadoHex: "D65C00"))
                .padding(.horizontal, 4)
        }
    }

    private func pageHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(JomadoTheme.navy)
            Text(subtitle)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Spacer(minLength: 10)
            Text(subtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func scheduleTimeRow(
        title: String,
        subtitle: String,
        symbol: String,
        selection: Binding<Date>
    ) -> some View {
        HStack(spacing: 12) {
            JomadoIconBadge(symbol: symbol, color: JomadoTheme.cyan, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Spacer()
            DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(JomadoTheme.cyan)
        }
    }

    private func styleChoice(
        title: String,
        subtitle: String,
        symbol: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(JomadoTheme.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                    Text(subtitle)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(JomadoTheme.secondaryText)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? JomadoTheme.cyan : Color.gray.opacity(0.35))
            }
            .foregroundStyle(JomadoTheme.navy)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 74)
            .background(selected ? JomadoTheme.sky.opacity(0.7) : .white, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? JomadoTheme.cyan : Color.gray.opacity(0.12), lineWidth: 1.2)
            }
        }
        .buttonStyle(.plain)
    }

    private func labeledTextField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.secondaryText)
            TextField(prompt, text: text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(JomadoTheme.navy)
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(JomadoTheme.sky.opacity(0.42), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func settingValueRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.navy)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.blue)
        }
    }

    private func reviewLine(symbol: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            JomadoIconBadge(symbol: symbol, color: JomadoTheme.cyan, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.secondaryText)
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
            }
            Spacer(minLength: 0)
        }
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
                .multilineTextAlignment(.trailing)
        }
    }

    private func primaryNextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "arrow.right")
        }
        .buttonStyle(JomadoPrimaryButtonStyle())
        .padding(.top, 2)
    }

    private func goBack() {
        validationMessage = nil
        if page == 0 {
            dismiss()
        } else {
            page -= 1
        }
    }

    private func validateSchedule() -> Bool {
        guard !selectedDays.isEmpty else {
            validationMessage = "Choose at least one day."
            return false
        }

        if scheduleMode == .interval {
            let start = LocalTime(date: startTime)
            let end = LocalTime(date: endTime)
            guard start != end else {
                validationMessage = "Choose different start and end times."
                return false
            }
            guard repeatMinutes > 0 else {
                validationMessage = "Choose a valid repeat interval."
                return false
            }
        } else {
            guard !fixedTimes.isEmpty else {
                validationMessage = "Add at least one reminder time."
                return false
            }
        }

        validationMessage = nil
        return true
    }

    private func validateCustomization() -> Bool {
        guard !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Give this routine a name."
            return false
        }
        guard !completionLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Add a completion label so the action is explicit."
            return false
        }
        validationMessage = nil
        return true
    }

    private func saveRoutine() {
        guard validateSchedule(), validateCustomization() else { return }

        let calendar = Calendar.current
        let schedule: RoutineSchedule
        if scheduleMode == .interval {
            schedule = .interval(
                start: LocalTime(date: startTime, calendar: calendar),
                end: LocalTime(date: endTime, calendar: calendar),
                everyMinutes: repeatMinutes,
                weekdays: selectedDays
            )
        } else {
            let times = Array(Set(fixedTimes.map { LocalTime(date: $0, calendar: calendar) })).sorted()
            schedule = .fixed(times: times, weekdays: selectedDays)
        }

        let draft = RoutineDraft(
            type: selectedType,
            name: routineName.trimmingCharacters(in: .whitespacesAndNewlines),
            schedule: schedule,
            deliveryMode: usesAlarm ? .alarmAndCompanion : .companionOnly,
            personality: personality,
            intensity: intensity,
            smartSnoozeEnabled: smartSnoozeEnabled,
            snoozeMinutes: snoozeMinutes,
            maxSnoozes: maxSnoozes,
            symbolName: selectedSymbol,
            accentHex: selectedAccent,
            completionLabel: completionLabel.trimmingCharacters(in: .whitespacesAndNewlines),
            mascotID: "momo",
            goal: goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : goal.trimmingCharacters(in: .whitespacesAndNewlines),
            contentTipEnabled: contentTipEnabled
        )

        validationMessage = nil
        onSave(draft)
        dismiss()
    }

    private func applyDefaults(for type: RoutineType) {
        routineName = type == .custom ? "My Routine" : type.displayName
        completionLabel = type.defaultCompletionLabel
        selectedSymbol = type.symbolName
        selectedAccent = type.accentHex
        goal = ""

        switch type {
        case .hydration:
            scheduleMode = .interval
            repeatMinutes = 120
            startTime = date(hour: 8)
            endTime = date(hour: 22)
        case .eyeCare:
            scheduleMode = .interval
            repeatMinutes = 60
            startTime = date(hour: 9)
            endTime = date(hour: 18)
        case .posture:
            scheduleMode = .interval
            repeatMinutes = 90
            startTime = date(hour: 9)
            endTime = date(hour: 18)
        case .exercise:
            scheduleMode = .fixedTimes
            fixedTimes = [date(hour: 18)]
        case .stretching:
            scheduleMode = .fixedTimes
            fixedTimes = [date(hour: 8), date(hour: 20)]
        case .breathing:
            scheduleMode = .fixedTimes
            fixedTimes = [date(hour: 12)]
        case .meditation:
            scheduleMode = .fixedTimes
            fixedTimes = [date(hour: 7)]
        case .yoga:
            scheduleMode = .fixedTimes
            fixedTimes = [date(hour: 7, minute: 30)]
        case .sleep:
            scheduleMode = .fixedTimes
            fixedTimes = [date(hour: 22, minute: 30)]
        case .custom, .generic:
            scheduleMode = .fixedTimes
            fixedTimes = [date(hour: 9)]
        }
    }

    private func date(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
    }

    private var scheduleSummary: String {
        switch scheduleMode {
        case .interval:
            return "\(repeatLabel(repeatMinutes)) • \(startTime.formatted(date: .omitted, time: .shortened))–\(endTime.formatted(date: .omitted, time: .shortened))"
        case .fixedTimes:
            return fixedTimes
                .map { $0.formatted(date: .omitted, time: .shortened) }
                .joined(separator: ", ")
        }
    }

    private var daySummary: String {
        if selectedDays.count == Weekday.allCases.count { return "Every day" }
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        if selectedDays == weekdays { return "Weekdays" }
        return Weekday.allCases.filter(selectedDays.contains).map(\.shortName).joined(separator: ", ")
    }

    private func repeatLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "Every \(minutes) min" }
        if minutes % 60 == 0 {
            let hours = minutes / 60
            return "Every \(hours) hour\(hours == 1 ? "" : "s")"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        return "Every \(hours)h \(remainder)m"
    }

    private func shortDescription(for type: RoutineType) -> String {
        switch type {
        case .hydration: "Drink more water"
        case .exercise: "Move your body"
        case .stretching: "Feel looser"
        case .eyeCare: "Give your eyes a break"
        case .posture: "Sit and stand better"
        case .breathing: "Feel calmer"
        case .meditation: "Be more mindful"
        case .yoga: "Build balance"
        case .sleep: "Rest better"
        case .custom: "Create your own routine"
        case .generic: "Build a habit"
        }
    }

    private func goalPrompt(for type: RoutineType) -> String {
        switch type {
        case .hydration: "Example: Drink water more consistently"
        case .exercise: "Example: Move for 30 minutes"
        case .stretching: "Example: Reduce stiffness"
        case .eyeCare: "Example: Take regular screen breaks"
        case .posture: "Example: Reset posture during work"
        case .breathing: "Example: Pause and reset"
        case .meditation: "Example: Build a daily mindfulness habit"
        case .yoga: "Example: Improve mobility and balance"
        case .sleep: "Example: Start winding down on time"
        case .custom, .generic: "What do you want this routine to help with?"
        }
    }

    private var symbolOptions: [String] {
        Array(Set([selectedType.symbolName, "star.fill", "heart.fill", "bolt.fill", "leaf.fill", "sparkles"]))
            .sorted()
    }

    private var accentOptions: [String] {
        [selectedType.accentHex, "13BDEB", "23C987", "7C5CFC", "FF8A2B", "FF6B6B", "8F68E8"]
            .reduce(into: [String]()) { result, value in
                if !result.contains(value) { result.append(value) }
            }
    }

    private var availableTypes: [RoutineType] {
        [.hydration, .exercise, .stretching, .eyeCare, .yoga, .posture, .breathing, .meditation, .sleep, .custom]
    }
}

private enum RoutineScheduleMode: String, CaseIterable, Identifiable {
    case interval
    case fixedTimes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interval: "Window + Interval"
        case .fixedTimes: "Fixed Times"
        }
    }
}

#Preview {
    AddRoutineFlowView(onSave: { _ in })
}
