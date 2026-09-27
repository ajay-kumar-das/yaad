import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: JomadoAppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    progressCard
                    nextUpCard
                    quickActions

                    #if DEBUG
                    previewTools
                    #endif
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .jomadoPageBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Jomado")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text(model.occurrence.status == .completed ? "Nice work today!" : "Good morning!")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("A healthier, happier you is in the making. 💙")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }

            Spacer(minLength: 0)

            AnimatedMomoView(
                expression: model.occurrence.status == .completed ? .proud : .hello,
                cue: model.occurrence.status == .completed ? .celebrate : .idleFloat,
                accessibilityLabel: model.occurrence.status == .completed
                    ? "Momo looks proud"
                    : "Momo waves hello"
            )
            .frame(width: 130, height: 130)
        }
        .padding(.top, 12)
    }

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(JomadoTheme.sky, lineWidth: 13)
                Circle()
                    .trim(from: 0, to: model.occurrence.status == .completed ? 1 : 0.66)
                    .stroke(
                        AngularGradient(colors: [JomadoTheme.cyan, Color(jomadoHex: "2BC9C3")], center: .center),
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(model.occurrence.status == .completed ? "100%" : "67%")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
            }
            .frame(width: 92, height: 92)
            .accessibilityLabel("Today's progress, \(model.occurrence.status == .completed ? 100 : 67) percent")

            VStack(alignment: .leading, spacing: 7) {
                Text("Today's Progress")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(model.occurrence.status == .completed ? "4 of 5 routines completed" : "3 of 5 routines completed")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
                Label("You're on track!", systemImage: "arrow.up.right")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.success)
            }
            Spacer()
        }
        .jomadoCard()
    }

    private var nextUpCard: some View {
        Button {
            if !model.occurrence.status.isTerminal {
                model.openReminder()
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: model.occurrence.status == .completed ? "checkmark.circle.fill" : "drop.fill")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(model.occurrence.status == .completed ? JomadoTheme.success : JomadoTheme.cyan)
                    .frame(width: 52, height: 52)
                    .background(JomadoTheme.sky, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.occurrence.status == .completed ? "Completed" : "Next up")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.secondaryText)
                    Text(model.occurrence.routineName)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                    Text(model.presentation.statusText)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color(jomadoHex: model.presentation.stage.accentHex))
                }

                Spacer()

                if !model.occurrence.status.isTerminal {
                    Text("View")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(JomadoTheme.blue)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(JomadoTheme.blue)
                }
            }
            .padding(16)
            .background(JomadoTheme.sky.opacity(0.8), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(model.occurrence.status.isTerminal)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            quickAction(title: "Open reminder", symbol: "bell.badge.fill", color: JomadoTheme.cyan) {
                model.openReminder()
            }
            quickAction(title: "View progress", symbol: "chart.bar.fill", color: Color(jomadoHex: "7C5CFC")) {}
            quickAction(title: "Get a nudge", symbol: "face.smiling.fill", color: Color(jomadoHex: "FFB020")) {
                model.openReminder()
            }
        }
    }

    private func quickAction(
        title: String,
        symbol: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
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
                Button("Start Live Activity") {
                    Task { await model.startLiveActivity() }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    Task { await model.resetPreview() }
                }
                .buttonStyle(.bordered)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ReminderUrgencyStage.allCases, id: \.self) { stage in
                        Button(stage.label) {
                            Task { await model.preview(stage: stage) }
                        }
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
}
