import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @AppStorage("jomado.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let rows = [
        SettingsRow(title: "Profile", subtitle: "Manage your personal information and preferences.", symbol: "person.fill", color: Color(jomadoHex: "20BDF0")),
        SettingsRow(title: "Reminder Settings", subtitle: "Customize when and how you get reminders.", symbol: "bell.fill", color: Color(jomadoHex: "FFB020")),
        SettingsRow(title: "Permissions", subtitle: "Manage notifications, alarms, and Live Activities.", symbol: "checkmark.shield.fill", color: Color(jomadoHex: "20C8B4")),
        SettingsRow(title: "Appearance", subtitle: "Choose your theme and visual preferences.", symbol: "circle.lefthalf.filled", color: Color(jomadoHex: "7C5CFC")),
        SettingsRow(title: "Data & Privacy", subtitle: "Control your local data and privacy.", symbol: "cylinder.fill", color: Color(jomadoHex: "20C985")),
        SettingsRow(title: "Help & Feedback", subtitle: "Get support or suggest a feature.", symbol: "ellipsis.message.fill", color: Color(jomadoHex: "FF5D74")),
        SettingsRow(title: "About", subtitle: "App information and privacy policy.", symbol: "info.circle.fill", color: JomadoTheme.blue)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    LazyVStack(spacing: 12) {
                        ForEach(rows) { row in
                            settingsRow(row)
                        }

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

    private func settingsRow(_ row: SettingsRow) -> some View {
        Button(action: {}) {
            HStack(spacing: 15) {
                JomadoIconBadge(symbol: row.symbol, color: row.color, size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                    Text(row.subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(JomadoTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if row.title == "About" {
                    Text("1.0.0")
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
        .buttonStyle(.plain)
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

private struct SettingsRow: Identifiable {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color

    var id: String { title }
}

#Preview {
    SettingsView()
        .environmentObject(JomadoAppModel())
}
