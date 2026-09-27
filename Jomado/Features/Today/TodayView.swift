import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: JomadoAppModel

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
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    JomadoBrandWordmark()
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(JomadoTheme.navy)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.88), in: Circle())
                    }
                    .accessibilityLabel("Notifications")
                }

                Spacer()

                Text(model.occurrence.status == .completed ? "Nice work today!" : "Good morning!")
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
                expression: model.occurrence.status == .completed ? .proud : .hello,
                cue: model.occurrence.status == .completed ? .celebrate : .idleFloat,
                accessibilityLabel: model.occurrence.status == .completed ? "Momo looks proud" : "Momo waves hello"
            )
            .frame(width: 188, height: 188)
            .offset(x: 78, y: 64)

            JomadoSpeechBubble(text: model.occurrence.status == .completed ? "You did it! 💙" : "You’re doing great today! 💙")
                .frame(maxWidth: 150)
                .offset(x: 104, y: 62)
        }
        .frame(height: 304)
    }

    private var progressCard: some View {
        HStack(spacing: 18) {
            JomadoProgressRing(
                progress: model.occurrence.status == .completed ? 1 : 0.67,
                color: JomadoTheme.cyan,
                label: model.occurrence.status == .completed ? "100%" : "67%",
                size: 108
            )

            VStack(alignment: .leading, spacing: 7) {
                Text("Today’s Progress")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(model.occurrence.status == .completed ? "4 of 5 routines completed" : "3 of 5 routines completed")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
                Label("You’re on track!", systemImage: "arrow.up.right")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.success)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(JomadoTheme.success.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            Spacer(minLength: 0)
        }
        .jomadoCard()
    }

    private var nextUpCard: some View {
        Button {
            if !model.occurrence.status.isTerminal { model.openReminder() }
        } label: {
            HStack(spacing: 13) {
                JomadoIconBadge(
                    symbol: model.occurrence.status == .completed ? "checkmark.circle.fill" : "bell.fill",
                    color: model.occurrence.status == .completed ? JomadoTheme.success : Color(jomadoHex: "FFB020"),
                    size: 52
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.occurrence.status == .completed ? "Completed" : "Next up")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(JomadoTheme.secondaryText)
                    Text(model.occurrence.routineName)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(JomadoTheme.navy)
                    Text(model.occurrence.status == .completed ? "Nice work" : "In 25 minutes  •  10:00 AM")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }
                Spacer()
                MomoArtwork(expression: model.occurrence.status == .completed ? .proud : .hopeful)
                    .frame(width: 46, height: 46)
                if !model.occurrence.status.isTerminal {
                    Label("View", systemImage: "chevron.right")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(JomadoTheme.blue)
                }
            }
            .padding(15)
            .background(JomadoTheme.sky.opacity(0.78), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(model.occurrence.status.isTerminal)
    }

    private var quickActions: some View {
        HStack(spacing: 9) {
            quickAction(title: "Log Water", symbol: "drop.fill", color: JomadoTheme.cyan) { model.openReminder() }
            quickAction(title: "Start Stretch", symbol: "figure.flexibility", color: Color(jomadoHex: "7C5CFC")) { model.openReminder() }
            quickAction(title: "View Progress", symbol: "chart.bar.fill", color: Color(jomadoHex: "20C985")) {}
            quickAction(title: "Get a Nudge", symbol: "face.smiling.fill", color: Color(jomadoHex: "FFB020")) { model.openReminder() }
        }
    }

    private var routineList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today’s Routines")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Spacer()
                Button("See All") {}
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.blue)
            }

            routineSummary(type: .hydration, name: "Hydration", detail: "8:00 AM–10:00 PM  •  Every 60 min", progress: "3 / 8", value: 0.38)
            routineSummary(type: .stretching, name: "Stretching", detail: "2 sessions today  •  5–10 min", progress: "1 / 2", value: 0.5)
            routineSummary(type: .eyeCare, name: "Eye Break", detail: "Every 20 min  •  20 sec", progress: "2 / 6", value: 0.33)
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

    private func routineSummary(type: RoutineType, name: String, detail: String, progress: String, value: Double) -> some View {
        HStack(spacing: 12) {
            JomadoIconBadge(symbol: type.symbolName, color: Color(jomadoHex: type.accentHex), size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
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
                    .stroke(Color(jomadoHex: type.accentHex), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 38, height: 38)
            Image(systemName: "chevron.right")
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .padding(13)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
}
