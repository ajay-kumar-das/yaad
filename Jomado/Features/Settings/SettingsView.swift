import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @AppStorage("jomado.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    LazyVStack(spacing: 12) {
                        staticRow(title: "Profile", subtitle: "Manage your personal information and preferences.", symbol: "person.fill", color: Color(jomadoHex: "20BDF0"))

                        NavigationLink {
                            ReminderPreferencesView()
                        } label: {
                            rowContent(title: "Reminder Settings", subtitle: "Personality, strictness, language, sound, and message style.", symbol: "bell.fill", color: Color(jomadoHex: "FFB020"))
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            PermissionsSettingsView()
                                .environmentObject(model)
                        } label: {
                            rowContent(title: "Permissions", subtitle: "Manage notifications and Live Activity readiness.", symbol: "checkmark.shield.fill", color: Color(jomadoHex: "20C8B4"))
                        }
                        .buttonStyle(.plain)

                        staticRow(title: "Appearance", subtitle: "Choose your theme and visual preferences.", symbol: "circle.lefthalf.filled", color: Color(jomadoHex: "7C5CFC"))
                        staticRow(title: "Data & Privacy", subtitle: "Control your local data and privacy.", symbol: "cylinder.fill", color: Color(jomadoHex: "20C985"))
                        staticRow(title: "Help & Feedback", subtitle: "Get support or suggest a feature.", symbol: "ellipsis.message.fill", color: Color(jomadoHex: "FF5D74"))
                        staticRow(title: "About", subtitle: "App information and privacy policy.", symbol: "info.circle.fill", color: JomadoTheme.blue, trailing: "1.0.0")

                        #if DEBUG
                        debugCard
                        #endif
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
                Text("Settings")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("Customize your experience\nand keep every routine just right.")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: .hello,
                cue: .idleFloat,
                accessibilityLabel: "Momo sits happily in Settings"
            )
            .frame(width: 176, height: 176)
            .offset(x: 92, y: 70)
        }
        .frame(height: 274)
    }

    private func staticRow(
        title: String,
        subtitle: String,
        symbol: String,
        color: Color,
        trailing: String? = nil
    ) -> some View {
        rowContent(title: title, subtitle: subtitle, symbol: symbol, color: color, trailing: trailing)
    }

    private func rowContent(
        title: String,
        subtitle: String,
        symbol: String,
        color: Color,
        trailing: String? = nil
    ) -> some View {
        HStack(spacing: 15) {
            JomadoIconBadge(symbol: symbol, color: color, size: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Image(systemName: "chevron.right")
                .font(.system(.body, weight: .bold))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .padding(16)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: JomadoTheme.navy.opacity(0.06), radius: 12, y: 6)
    }

    #if DEBUG
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer previews")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)

            Button("Send notification in 5 seconds") {
                Task { await model.requestNotificationsAndSchedulePreview() }
            }
            Button("Start Live Activity") {
                Task { await model.startLiveActivity() }
            }
            Button("Repair schedules now") {
                Task { await model.reconcileSchedules() }
            }
            Button("Show onboarding again") {
                hasCompletedOnboarding = false
            }

            if let message = model.systemMessage {
                Text(message)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
        }
        .tint(JomadoTheme.blue)
        .jomadoCard()
    }
    #endif
}

private struct ReminderPreferencesView: View {
    @AppStorage("jomado.defaultPersonality") private var personalityRaw = ReminderPersonality.playful.rawValue
    @AppStorage("jomado.defaultIntensity") private var intensityRaw = ReminderIntensity.balanced.rawValue
    @AppStorage("jomado.language") private var language = "en"
    @AppStorage("jomado.emojiLevel") private var emojiLevel = "balanced"
    @AppStorage("jomado.messageLength") private var messageLength = "standard"
    @AppStorage("jomado.soundEnabled") private var legacySoundEnabled = true
    @AppStorage("jomado.defaultNotificationSound") private var defaultNotificationSoundRaw = NotificationSoundChoice.systemDefault.rawValue
    private var selectedPersonalities: Set<ReminderPersonality> {
        let values = personalityRaw.split(separator: "|").compactMap { ReminderPersonality(rawValue: String($0)) }
        return Set(values.isEmpty ? [.playful] : values)
    }
    private var previewPersonality: ReminderPersonality { selectedPersonalities.sorted { $0.rawValue < $1.rawValue }.first ?? .playful }
    private var defaultNotificationSound: Binding<NotificationSoundChoice> {
        Binding(get: {
            if let value = NotificationSoundChoice(rawValue: defaultNotificationSoundRaw), value != .inherit { return value }
            return legacySoundEnabled ? .systemDefault : .silent
        }, set: { defaultNotificationSoundRaw = $0.rawValue; legacySoundEnabled = $0 != .silent })
    }

    private var intensity: Binding<ReminderIntensity> {
        Binding(
            get: { ReminderIntensity(rawValue: intensityRaw) ?? .balanced },
            set: { intensityRaw = $0.rawValue }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Reminder personality")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("These defaults apply to new routines. Each routine can override them.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)

                settingCard(title: "Tone") {
                    Text("Choose one or more default personalities for new routines.").font(.system(.caption, design: .rounded)).foregroundStyle(JomadoTheme.secondaryText)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 116), spacing: 8)], spacing: 8) {
                        ForEach(ReminderPersonality.allCases, id: \.self) { option in
                            Button { togglePersonality(option) } label: {
                                HStack(spacing: 6) { Image(systemName: selectedPersonalities.contains(option) ? "checkmark.circle.fill" : "circle"); Text(option.displayName).lineLimit(1).minimumScaleFactor(0.75) }
                                    .font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(selectedPersonalities.contains(option) ? JomadoTheme.blue : JomadoTheme.navy)
                                    .frame(maxWidth: .infinity, minHeight: 40).background(selectedPersonalities.contains(option) ? JomadoTheme.sky.opacity(0.7) : Color.white, in: Capsule())
                            }.buttonStyle(.plain)
                        }
                    }
                }

                settingCard(title: "Strictness") {
                    Picker("Intensity", selection: intensity) {
                        ForEach(ReminderIntensity.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                settingCard(title: "Language & copy") {
                    Picker("Language", selection: $language) {
                        Text("English").tag("en")
                    }
                    Picker("Emoji", selection: $emojiLevel) {
                        Text("Minimal").tag("minimal")
                        Text("Balanced").tag("balanced")
                        Text("Expressive").tag("expressive")
                    }
                    Picker("Message length", selection: $messageLength) {
                        Text("Short").tag("short")
                        Text("Standard").tag("standard")
                    }
                    Picker("Default notification sound", selection: defaultNotificationSound) { ForEach(NotificationSoundChoice.globalChoices, id: \.self) { Text($0.displayName).tag($0) } }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                    HStack(spacing: 12) {
                        MomoArtwork(expression: previewExpression)
                            .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Hydration")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(JomadoTheme.secondaryText)
                            Text(previewCopy)
                                .font(.system(.body, design: .rounded, weight: .bold))
                                .foregroundStyle(JomadoTheme.navy)
                        }
                    }
                }
                .jomadoCard()
            }
            .padding(18)
        }
        .jomadoPageBackground()
        .navigationTitle("Reminder Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            content()
        }
        .jomadoCard()
    }

    private func togglePersonality(_ option: ReminderPersonality) {
        var values = selectedPersonalities
        if values.contains(option) { guard values.count > 1 else { return }; values.remove(option) } else { values.insert(option) }
        personalityRaw = values.sorted { $0.rawValue < $1.rawValue }.map(\.rawValue).joined(separator: "|")
    }

    private var previewCopy: String {
        switch (previewPersonality, intensity.wrappedValue) {
        case (.strict, .firm): "Water break due. Drink water now."
        case (.dramatic, _): "Momo has declared a hydration emergency. 💧"
        case (.cute, .soft): "Tiny water mission for you 💧"
        case (.charming, _): "A little water break would look good on you. 💙"
        case (.focused, _): "Hydration break. One glass, then continue."
        case (.gentle, _): "A gentle reminder to have some water."
        case (.cheeky, _): "Your water is feeling ignored. Fix that? 😌"
        default: "Quick water break? Momo is cheering for you. 💧"
        }
    }

    private var previewExpression: MascotExpression {
        switch previewPersonality {
        case .strict, .focused: .focused
        case .dramatic: .dramatic
        case .cheeky: .cheeky
        case .gentle: .hopeful
        default: .hello
        }
    }
}

private struct PermissionsSettingsView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Delivery permissions")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("Jomado saves routines even when permission is denied. System delivery only works when iOS allows it.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)

                permissionCard(
                    title: "Notifications",
                    body: "Used for companion reminders and as fallback delivery when a prominent alarm is unavailable.",
                    symbol: "bell.fill"
                ) {
                    Task {
                        _ = await model.requestNotificationAuthorization()
                        await model.reconcileSchedules()
                    }
                }

                permissionCard(
                    title: "Alarm + Companion",
                    body: "Allows routines you explicitly configure for alarm delivery to use iOS AlarmKit.",
                    symbol: "alarm.fill"
                ) {
                    Task {
                        _ = await model.requestAlarmAuthorization()
                    }
                }

                permissionCard(
                    title: "Live Activities",
                    body: "Provides persistent Lock Screen and Dynamic Island context when supported.",
                    symbol: "iphone.gen3"
                ) {
                    Task { await model.startLiveActivity() }
                }

                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(JomadoPrimaryButtonStyle())

                if let message = model.systemMessage {
                    Text(message)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }
            }
            .padding(18)
        }
        .jomadoPageBackground()
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func permissionCard(
        title: String,
        body: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text(body)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
            Button("Enable / Test", action: action)
                .buttonStyle(.borderedProminent)
                .tint(JomadoTheme.cyan)
        }
        .jomadoCard()
    }
}

#Preview {
    SettingsView()
        .environmentObject(JomadoAppModel())
}
