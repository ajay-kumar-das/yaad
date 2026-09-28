import SwiftUI

struct OnboardingFlowView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var model: JomadoAppModel
    @State private var step = 1
    @State private var ageRange = "25–34"
    @State private var gender = "Prefer not to say"
    @State private var selectedGoals: Set<String> = ["Stay healthy", "Reduce screen strain", "Build consistency"]
    @State private var selectedRoutines: Set<RoutineType> = [.hydration]
    @State private var notificationsEnabled = false
    @State private var alarmEnabled = false
    @State private var isEnablingPermissions = false
    @State private var showLearnMore = false

    @AppStorage("jomado.profile.ageRange") private var storedAgeRange = ""
    @AppStorage("jomado.profile.gender") private var storedGender = ""
    @AppStorage("jomado.profile.goals") private var storedGoals = ""
    @AppStorage("jomado.profile.focusAreas") private var storedFocusAreas = ""

    var body: some View {
        ZStack {
            JomadoTheme.pageGradient.ignoresSafeArea()

            GeometryReader { _ in
                ViewThatFits(in: .vertical) {
                    onboardingPage

                    ScrollView {
                        onboardingPage
                    }
                    .id(step)
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: step)
        .sheet(isPresented: $showLearnMore) {
            learnMoreSheet
        }
    }

    private var onboardingPage: some View {
        VStack(spacing: 0) {
            hero

            Group {
                switch step {
                case 1: welcomeContent
                case 2: profileContent
                case 3: focusContent
                case 4: permissionsContent
                default: allSetContent
                }
            }
            .id(step)
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            .padding(.horizontal, 18)
            .padding(.top, step == 1 || step == 5 ? 16 : 8)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            HStack {
                if step > 1 && step < 5 {
                    Button {
                        step -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .heavy))
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.9), in: Circle())
                    }
                    .foregroundStyle(JomadoTheme.navy)
                    .accessibilityLabel("Previous step")
                }

                JomadoBrandWordmark()
                Spacer()

                if (2...4).contains(step) {
                    VStack(alignment: .trailing, spacing: 7) {
                        JomadoStepIndicator(current: step, total: 4)
                        Text("Step \(step) of 4")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(JomadoTheme.navy)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: step == 5 ? .celebrating : (step == 4 ? .hopeful : .hello),
                cue: step == 5 ? .celebrate : (step == 4 ? .gentleBounce : .wave),
                accessibilityLabel: step == 5 ? "Momo celebrates that setup is complete" : "Momo welcomes you to Jomado"
            )
            .frame(
                width: step == 1 || step == 5 ? 210 : (step == 4 ? 166 : 126),
                height: step == 1 || step == 5 ? 210 : (step == 4 ? 166 : 126)
            )
            .offset(
                x: step == 1 ? -26 : (step == 5 ? 0 : (step == 4 ? 36 : 28)),
                y: step == 1 ? 48 : (step == 4 ? 42 : 38)
            )

            if step != 5 {
                JomadoSpeechBubble(text: heroMessage)
                    .frame(maxWidth: step == 1 ? 184 : (step == 4 ? 168 : 150))
                    .offset(
                        x: step == 1 ? 98 : (step == 4 ? -82 : -70),
                        y: step == 1 ? 78 : (step == 4 ? 54 : 48)
                    )
            }
        }
        .frame(
            height: step == 1 ? 282
                : (step == 2 ? 164
                    : (step == 3 ? 150
                        : (step == 4 ? 218 : 270)))
        )
    }

    private var heroMessage: String {
        switch step {
        case 1: "Small steps create a brighter, healthier you! 💙"
        case 2: "Let’s tailor Jomado to you! 💙"
        case 3: "Pick what matters most to you!"
        default: "A few quick permissions help me take care of you! 💙"
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 14) {
            onboardingTitle("Build healthy", accent: "daily habits")

            Text("Jomado helps you take care of yourself with friendly reminders and gentle support for a healthier, happier you.")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(welcomeRoutines.indices, id: \.self) { index in
                    let item = welcomeRoutines[index]
                    VStack(spacing: 5) {
                        JomadoIconBadge(symbol: item.1, color: item.2, size: 44)
                        Text(item.0)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(JomadoTheme.navy)
                    }
                    .frame(maxWidth: .infinity, minHeight: 76)
                    .background(item.2.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(12)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            nextButton(title: "Get Started", target: 2)

            Button("Learn More") { showLearnMore = true }
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.blue)
                .frame(minHeight: 44)
        }
    }

    private var profileContent: some View {
        VStack(spacing: 8) {
            onboardingTitle("Tell us a bit", accent: "about you!")
            Text("A few quick details help Jomado personalize your reminders.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)

            compactOnboardingCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How old are you?")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)

                    Picker("Age range", selection: $ageRange) {
                        ForEach(["Under 18", "18–24", "25–34", "35–44", "45–54", "55–64", "65+"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(JomadoTheme.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 42)
                    .background(
                        JomadoTheme.sky.opacity(0.48),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                }
            }

            compactOnboardingCard {
                VStack(alignment: .leading, spacing: 7) {
                    Text("What’s your gender?")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)

                    HStack(spacing: 7) {
                        genderChoice(title: "Woman", glyph: "♀", color: Color(jomadoHex: "E968A8"))
                        genderChoice(title: "Man", glyph: "♂", color: JomadoTheme.blue)
                        genderChoice(title: "Non-binary", glyph: "⚧", color: Color(jomadoHex: "7C5CFC"))
                    }
                }
            }

            compactOnboardingCard {
                VStack(alignment: .leading, spacing: 7) {
                    Text("What are your wellness goals?")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 6
                    ) {
                        ForEach(goalOptions) { goal in
                            choiceButton(
                                title: goal.title,
                                symbol: goal.symbol,
                                selected: selectedGoals.contains(goal.title)
                            ) {
                                if selectedGoals.contains(goal.title) {
                                    selectedGoals.remove(goal.title)
                                } else {
                                    selectedGoals.insert(goal.title)
                                }
                            }
                        }
                    }
                }
            }

            nextButton(title: "Next", target: 3)
        }
    }

    private var focusContent: some View {
        VStack(spacing: 8) {
            onboardingTitle("Choose your", accent: "focus areas")
            Text("Select the habits you’d like to build. You can change these later.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach(focusRoutines, id: \.self) { routine in
                    let selected = selectedRoutines.contains(routine)
                    let accent = Color(jomadoHex: routine.accentHex)

                    Button {
                        if selected {
                            selectedRoutines.remove(routine)
                        } else {
                            selectedRoutines.insert(routine)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            JomadoIconBadge(
                                symbol: routine.symbolName,
                                color: accent,
                                size: 40
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.displayName)
                                    .font(.system(.caption, design: .rounded, weight: .heavy))
                                    .foregroundStyle(JomadoTheme.navy)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)

                                Text(focusSubtitle(for: routine))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(JomadoTheme.secondaryText)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                        .background(
                            selected ? accent.opacity(0.14) : Color.white.opacity(0.92),
                            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(
                                    selected ? accent : Color.gray.opacity(0.12),
                                    lineWidth: selected ? 2 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            nextButton(title: "Next", target: 4)

            Button("Maybe later") {
                selectedRoutines.removeAll()
                step = 4
            }
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(JomadoTheme.blue)
            .frame(minHeight: 34)
        }
    }

    private var permissionsContent: some View {
        VStack(spacing: 10) {
            onboardingTitle("Let’s get Jomado", accent: "ready to help you!")
            Text("These permissions help Jomado send reminders, keep you on track, and show timely updates.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            permissionRow(
                title: "Notifications",
                subtitle: "Friendly reminders, motivation, and progress updates.",
                symbol: "bell.fill",
                color: Color(jomadoHex: "FF4D5A"),
                status: notificationsEnabled ? "Allowed" : "Not enabled",
                enabled: notificationsEnabled
            )

            permissionRow(
                title: "Alarms & Alerts",
                subtitle: "Sound reminders so you don’t miss important routines.",
                symbol: "alarm.fill",
                color: JomadoTheme.blue,
                status: alarmEnabled ? "Allowed" : "Not enabled",
                enabled: alarmEnabled
            )

            permissionRow(
                title: "Live Activities",
                subtitle: "Show your next reminder on the Lock Screen.",
                symbol: "iphone.gen3",
                color: Color(jomadoHex: "20C8B4"),
                status: model.liveActivitiesEnabled ? "Available" : "Disabled",
                enabled: model.liveActivitiesEnabled
            )

            Button {
                Task { await enablePermissionsSequentially() }
            } label: {
                if isEnablingPermissions {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Enable All", systemImage: "arrow.right")
                }
            }
            .buttonStyle(JomadoPrimaryButtonStyle())
            .disabled(isEnablingPermissions)

            Button("Maybe Later") { step = 5 }
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.blue)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(.white.opacity(0.76), in: Capsule())
        }
    }

    private var allSetContent: some View {
        VStack(spacing: 18) {
            onboardingTitle("You’re", accent: "all set!")
            Text("Momo is ready. Your starter routines and reminder preferences can be changed anytime.")
                .onboardingSubtitle()

            VStack(alignment: .leading, spacing: 14) {
                Text("Readiness")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)

                readinessLine(title: "Notifications", enabled: notificationsEnabled)
                readinessLine(title: "Alarms & Alerts", enabled: alarmEnabled)
                readinessLine(title: "Live Activities", enabled: model.liveActivitiesEnabled)
            }
            .jomadoCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("Your focus areas")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)

                if selectedRoutines.isEmpty {
                    Text("No starter routines selected — you can add one anytime from Routines.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(JomadoTheme.secondaryText)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                        ForEach(focusRoutines.filter(selectedRoutines.contains), id: \.self) { routine in
                            Label(routine.displayName, systemImage: routine.symbolName)
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(JomadoTheme.navy)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                                .background(Color(jomadoHex: routine.accentHex).opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
                        }
                    }
                }
            }
            .jomadoCard()

            Button {
                persistSelections()
                Task {
                    await model.createStarterRoutines(for: selectedRoutines)
                    onFinish()
                }
            } label: {
                Label("Start My Journey", systemImage: "arrow.right")
            }
            .buttonStyle(JomadoPrimaryButtonStyle())
        }
    }

    private var learnMoreSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AnimatedMomoView(
                        expression: .hello,
                        cue: .wave,
                        accessibilityLabel: "Momo introduces Jomado"
                    )
                    .frame(width: 160, height: 160)

                    Text("A companion for small daily habits")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                        .multilineTextAlignment(.center)

                    walkthroughRow("Friendly reminders", "Messages adapt to your routine, personality, and urgency.", "message.fill")
                    walkthroughRow("Clear outcomes", "Complete, remind later, or skip — dismissing never pretends you completed a habit.", "checkmark.circle.fill")
                    walkthroughRow("Works with iOS", "Notifications, alarms, and Live Activities are used only when the system allows them.", "iphone")
                }
                .padding(24)
            }
            .jomadoPageBackground()
            .navigationTitle("About Jomado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showLearnMore = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func walkthroughRow(_ title: String, _ body: String, _ symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            JomadoIconBadge(symbol: symbol, color: JomadoTheme.cyan, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(body)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .jomadoCard()
    }

    private func onboardingTitle(_ first: String, accent: String) -> some View {
        VStack(spacing: 0) {
            Text(first)
                .foregroundStyle(JomadoTheme.navy)
            Text(accent)
                .foregroundStyle(JomadoTheme.blue)
        }
        .font(.system(size: 34, weight: .heavy, design: .rounded))
        .lineLimit(2)
        .minimumScaleFactor(0.82)
        .allowsTightening(true)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func nextButton(title: String, target: Int) -> some View {
        Button {
            step = target
        } label: {
            Label(title, systemImage: "arrow.right")
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(JomadoPrimaryButtonStyle())
        .padding(.top, 4)
    }

    private func profileCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .jomadoCard()
    }

    private func compactOnboardingCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.white.opacity(0.82),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
    }

    private func genderChoice(
        title: String,
        glyph: String,
        color: Color
    ) -> some View {
        let selected = gender == title

        return Button {
            gender = title
        } label: {
            VStack(spacing: 3) {
                Text(glyph)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                selected ? color.opacity(0.14) : Color.white,
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        selected ? color : Color.gray.opacity(0.12),
                        lineWidth: selected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func choiceButton(
        title: String,
        symbol: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selected ? JomadoTheme.blue : JomadoTheme.secondaryText)

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(
                selected ? JomadoTheme.sky.opacity(0.82) : Color.white,
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        selected ? JomadoTheme.blue : Color.gray.opacity(0.12),
                        lineWidth: selected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func permissionRow(
        title: String,
        subtitle: String,
        symbol: String,
        color: Color,
        status: String,
        enabled: Bool
    ) -> some View {
        HStack(spacing: 14) {
            JomadoIconBadge(symbol: symbol, color: color, size: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Spacer()
            Text(status)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(enabled ? JomadoTheme.success : Color(jomadoHex: "E77B16"))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    (enabled ? JomadoTheme.success : Color(jomadoHex: "FFB020")).opacity(0.12),
                    in: Capsule()
                )

            Image(systemName: "chevron.right")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .jomadoCard()
    }

    private func readinessLine(title: String, enabled: Bool) -> some View {
        HStack {
            Image(systemName: enabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(enabled ? JomadoTheme.success : Color(jomadoHex: "FFB020"))
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.navy)
            Spacer()
            Text(enabled ? "Ready" : "Can enable later")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
    }

    private func enablePermissionsSequentially() async {
        guard !isEnablingPermissions else { return }
        isEnablingPermissions = true
        notificationsEnabled = await model.requestNotificationAuthorization()
        if !selectedRoutines.isEmpty {
            alarmEnabled = await model.requestAlarmAuthorization()
        }
        isEnablingPermissions = false
        step = 5
    }

    private func persistSelections() {
        storedAgeRange = ageRange
        storedGender = gender
        storedGoals = selectedGoals.sorted().joined(separator: "|")
        storedFocusAreas = selectedRoutines.map(\.rawValue).sorted().joined(separator: "|")
    }

    private func focusSubtitle(for routine: RoutineType) -> String {
        switch routine {
        case .hydration: "Drink more water daily."
        case .exercise: "Move your body more."
        case .stretching: "Feel looser and less tense."
        case .eyeCare: "Give your eyes a break."
        case .posture: "Sit and stand healthier."
        case .breathing: "Find calm in every breath."
        case .meditation: "Be present and centered."
        case .yoga: "Build strength and balance."
        case .sleep: "Rest better and feel brighter."
        case .custom: "Create your own habit."
        case .generic: "Build a healthy habit."
        }
    }

    private var welcomeRoutines: [(String, String, Color)] {
        [
            ("Hydration", "drop.fill", JomadoTheme.cyan),
            ("Stretching", "figure.flexibility", Color(jomadoHex: "7C5CFC")),
            ("Eye Care", "eye.fill", JomadoTheme.blue),
            ("Breathing", "wind", Color(jomadoHex: "2BC9C3")),
            ("Meditation", "figure.mind.and.body", Color(jomadoHex: "E968A8")),
            ("Posture", "figure.stand", Color(jomadoHex: "FF9F1C")),
            ("Yoga", "figure.yoga", Color(jomadoHex: "6556D8")),
            ("Sleep", "moon.stars.fill", Color(jomadoHex: "677CE8")),
            ("Exercise", "figure.run", Color(jomadoHex: "20C985"))
        ]
    }

    private var focusRoutines: [RoutineType] {
        [.hydration, .exercise, .stretching, .eyeCare, .posture, .breathing, .meditation, .yoga, .sleep, .custom]
    }

    private var goalOptions: [OnboardingChoice] {
        [
            OnboardingChoice(title: "Stay healthy", symbol: "heart.fill"),
            OnboardingChoice(title: "Be more active", symbol: "figure.run"),
            OnboardingChoice(title: "Reduce screen strain", symbol: "laptopcomputer"),
            OnboardingChoice(title: "Improve focus", symbol: "brain.head.profile"),
            OnboardingChoice(title: "Manage stress", symbol: "leaf.fill"),
            OnboardingChoice(title: "Build consistency", symbol: "chart.bar.fill")
        ]
    }
}

private struct OnboardingChoice: Identifiable {
    let title: String
    let symbol: String

    var id: String { title }
}

private extension View {
    func onboardingSubtitle() -> some View {
        font(.system(.body, design: .rounded, weight: .medium))
            .foregroundStyle(JomadoTheme.secondaryText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

#Preview {
    OnboardingFlowView(onFinish: {})
        .environmentObject(JomadoAppModel())
}
