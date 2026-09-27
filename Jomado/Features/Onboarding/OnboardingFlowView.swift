import SwiftUI

struct OnboardingFlowView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var model: JomadoAppModel
    @State private var step = 1
    @State private var ageRange = "25–34"
    @State private var gender = "Prefer not to say"
    @State private var selectedGoals: Set<String> = ["Stay healthy", "Build routine"]
    @State private var selectedRoutines: Set<RoutineType> = [.hydration]
    @State private var notificationsEnabled = false

    var body: some View {
        ZStack {
            JomadoTheme.pageGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    hero

                    Group {
                        switch step {
                        case 1: welcomeContent
                        case 2: profileContent
                        case 3: focusContent
                        default: permissionsContent
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: step)
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            HStack {
                if step > 1 {
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

                if step > 1 {
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
                expression: step == 4 ? .hopeful : .hello,
                cue: step == 4 ? .gentleBounce : .wave,
                accessibilityLabel: "Momo welcomes you to Jomado"
            )
            .frame(width: step == 1 ? 224 : 176, height: step == 1 ? 224 : 176)
            .offset(x: step == 1 ? -34 : 34, y: step == 1 ? 52 : 58)

            JomadoSpeechBubble(text: heroMessage)
                .frame(maxWidth: 182)
                .offset(x: step == 1 ? 102 : -92, y: 82)
        }
        .frame(height: step == 1 ? 310 : 244)
    }

    private var heroMessage: String {
        switch step {
        case 1: "Small steps create a brighter, healthier you! 💙"
        case 2: "Let’s tailor Jomado to you! 💙"
        case 3: "Pick what matters most to you!"
        default: "A few quick permissions help me take care of you!"
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            onboardingTitle("Build healthy", accent: "daily habits")

            Text("Jomado helps you take care of yourself with friendly reminders and gentle support for a healthier, happier you.")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(welcomeRoutines.indices, id: \.self) { index in
                    let item = welcomeRoutines[index]
                    VStack(spacing: 7) {
                        JomadoIconBadge(symbol: item.1, color: item.2, size: 50)
                        Text(item.0)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(JomadoTheme.navy)
                    }
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .background(item.2.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(12)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            nextButton(title: "Get Started", target: 2)

            Button("Learn More") {}
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.blue)
                .frame(minHeight: 44)
        }
    }

    private var profileContent: some View {
        VStack(spacing: 16) {
            onboardingTitle("Tell us a bit", accent: "about you!")
            Text("A few quick details help Jomado give you more personalized reminders and support.")
                .onboardingSubtitle()

            profileCard(title: "How old are you?", subtitle: "This helps us tailor your experience.") {
                Picker("Age range", selection: $ageRange) {
                    ForEach(["Under 18", "18–24", "25–34", "35–44", "45–54", "55+"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(JomadoTheme.navy)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(JomadoTheme.sky.opacity(0.52), in: RoundedRectangle(cornerRadius: 14))
            }

            profileCard(title: "What’s your gender?", subtitle: "Choose the option that fits you.") {
                HStack(spacing: 8) {
                    ForEach(["Female", "Male", "Non-binary"], id: \.self) { option in
                        choiceButton(title: option, symbol: "person.fill", selected: gender == option) {
                            gender = option
                        }
                    }
                }
            }

            profileCard(title: "What are your wellness goals?", subtitle: "Choose all that apply.") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
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

            nextButton(title: "Next", target: 3)
        }
    }

    private var focusContent: some View {
        VStack(spacing: 16) {
            onboardingTitle("Choose your", accent: "focus areas")
            Text("Select the habits you’d like to build. You can always change these later.")
                .onboardingSubtitle()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(focusRoutines, id: \.self) { routine in
                    Button {
                        if selectedRoutines.contains(routine) {
                            selectedRoutines.remove(routine)
                        } else {
                            selectedRoutines.insert(routine)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            JomadoIconBadge(
                                symbol: routine.symbolName,
                                color: Color(jomadoHex: routine.accentHex),
                                size: 48
                            )
                            VStack(alignment: .leading, spacing: 3) {
                                Text(routine.displayName)
                                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                Text(focusSubtitle(for: routine))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(JomadoTheme.secondaryText)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: selectedRoutines.contains(routine) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedRoutines.contains(routine) ? JomadoTheme.cyan : Color.gray.opacity(0.35))
                        }
                        .foregroundStyle(JomadoTheme.navy)
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 84)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(selectedRoutines.contains(routine) ? JomadoTheme.cyan : .clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            nextButton(title: "Next", target: 4)

            Button("Maybe later") { step = 4 }
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.blue)
                .frame(minHeight: 44)
        }
    }

    private var permissionsContent: some View {
        VStack(spacing: 16) {
            onboardingTitle("Let’s get Jomado", accent: "ready to help you!")
            Text("Enable the system surfaces that deliver reminders, show timely updates, and keep your routines within reach.")
                .onboardingSubtitle()

            permissionRow(
                title: "Notifications",
                subtitle: "Friendly reminders and completion actions.",
                symbol: "bell.fill",
                color: Color(jomadoHex: "FF4D5A"),
                status: notificationsEnabled ? "Enabled" : "Not enabled",
                enabled: notificationsEnabled
            )

            permissionRow(
                title: "Alarms & Alerts",
                subtitle: "Optional sound reminders for important routines.",
                symbol: "alarm.fill",
                color: JomadoTheme.blue,
                status: "Coming next",
                enabled: false
            )

            permissionRow(
                title: "Live Activities",
                subtitle: "Persistent status on the Lock Screen and Dynamic Island.",
                symbol: "iphone.gen3",
                color: Color(jomadoHex: "20C8B4"),
                status: model.liveActivitiesEnabled ? "Available" : "Disabled",
                enabled: model.liveActivitiesEnabled
            )

            Button {
                Task {
                    notificationsEnabled = await model.requestNotificationAuthorization()
                    onFinish()
                }
            } label: {
                Label("Enable All", systemImage: "arrow.right")
            }
            .buttonStyle(JomadoPrimaryButtonStyle())

            Button("Maybe later", action: onFinish)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(JomadoTheme.blue)
                .frame(minHeight: 44)
        }
    }

    private func onboardingTitle(_ first: String, accent: String) -> some View {
        VStack(spacing: 0) {
            Text(first)
                .foregroundStyle(JomadoTheme.navy)
            Text(accent)
                .foregroundStyle(JomadoTheme.blue)
        }
        .font(.system(size: 36, weight: .heavy, design: .rounded))
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

    private func choiceButton(
        title: String,
        symbol: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(selected ? JomadoTheme.cyan : JomadoTheme.secondaryText)
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(selected ? JomadoTheme.cyan : Color.gray.opacity(0.35))
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(selected ? JomadoTheme.sky.opacity(0.72) : Color.white, in: RoundedRectangle(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(selected ? JomadoTheme.cyan : Color.gray.opacity(0.14), lineWidth: 1.2)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    (enabled ? JomadoTheme.success : Color(jomadoHex: "FFB020")).opacity(0.12),
                    in: Capsule()
                )
        }
        .jomadoCard()
    }

    private func focusSubtitle(for routine: RoutineType) -> String {
        switch routine {
        case .hydration: "Drink more water"
        case .exercise: "Move your body"
        case .stretching: "Feel looser"
        case .eyeCare: "Rest your eyes"
        case .posture: "Sit and stand better"
        case .breathing: "Find calm"
        case .meditation: "Be present"
        case .yoga: "Build balance"
        case .sleep: "Rest better"
        case .custom: "Create your own"
        case .generic: "Build a habit"
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
        [.hydration, .exercise, .stretching, .eyeCare, .breathing, .meditation, .posture, .yoga, .sleep, .custom]
    }

    private var goalOptions: [OnboardingChoice] {
        [
            OnboardingChoice(title: "Stay healthy", symbol: "heart.fill"),
            OnboardingChoice(title: "Be more active", symbol: "figure.run"),
            OnboardingChoice(title: "Reduce screen strain", symbol: "laptopcomputer"),
            OnboardingChoice(title: "Improve focus", symbol: "brain.head.profile"),
            OnboardingChoice(title: "Manage stress", symbol: "leaf.fill"),
            OnboardingChoice(title: "Build routine", symbol: "chart.bar.fill")
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
