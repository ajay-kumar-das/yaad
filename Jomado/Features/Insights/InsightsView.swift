import SwiftUI

struct InsightsView: View {
    @State private var period: InsightPeriod = .week

    private let week = [
        InsightDay(label: "Mon", value: 0.60),
        InsightDay(label: "Tue", value: 0.80),
        InsightDay(label: "Wed", value: 0.50),
        InsightDay(label: "Thu", value: 0.70),
        InsightDay(label: "Fri", value: 0.90),
        InsightDay(label: "Sat", value: 0.60),
        InsightDay(label: "Sun", value: 0.55)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(spacing: 16) {
                        Picker("Time period", selection: $period) {
                            ForEach(InsightPeriod.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        completionCard
                        trendCard
                        streakCard
                        routineProgressCard

                        Label(
                            "Silencing, dismissing, or snoozing is not completion—only an explicit completion action counts.",
                            systemImage: "info.circle.fill"
                        )
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.blue)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(JomadoTheme.sky.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
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
                Text("Your\nProgress")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                Text("Little steps add up to a\nhappier, healthier you.")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: .proud,
                cue: .idleFloat,
                accessibilityLabel: "Momo looks proud of your progress"
            )
            .frame(width: 176, height: 176)
            .offset(x: 86, y: 62)

            JomadoSpeechBubble(text: "You’re doing great! 💙")
                .frame(maxWidth: 150)
                .offset(x: 28, y: 58)
        }
        .frame(height: 270)
    }

    private var completionCard: some View {
        HStack(spacing: 20) {
            JomadoProgressRing(progress: 0.67, color: JomadoTheme.cyan, label: "67%", size: 112)

            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Completion")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text("You completed 47 of 70 reminders this week.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)

                HStack(spacing: 8) {
                    insightMetric(value: "47", label: "Done", color: JomadoTheme.success)
                    insightMetric(value: "12", label: "Open", color: JomadoTheme.blue)
                    insightMetric(value: "6", label: "Skipped", color: Color(jomadoHex: "FFB020"))
                }
            }
        }
        .jomadoCard()
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Trend")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text("Completion rate each day")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(week) { day in
                    VStack(spacing: 6) {
                        Text("\(Int(day.value * 100))%")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(JomadoTheme.navy)
                        RoundedRectangle(cornerRadius: 7)
                            .fill(
                                LinearGradient(
                                    colors: [JomadoTheme.cyan, Color(jomadoHex: "2BD5D2")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 118 * CGFloat(day.value))
                        Text(day.label)
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(JomadoTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 158, alignment: .bottom)
        }
        .jomadoCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly completion trend")
    }

    private var streakCard: some View {
        HStack(spacing: 18) {
            JomadoIconBadge(symbol: "flame.fill", color: Color(jomadoHex: "FF8A2B"), size: 62)
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                Text("6 days")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text("Keep going!")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Divider().frame(height: 64)
            JomadoIconBadge(symbol: "flame", color: Color(jomadoHex: "A6B6CB"), size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("Best Streak")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.secondaryText)
                Text("12 days")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
            }
        }
        .jomadoCard()
    }

    private var routineProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Progress by Routine")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            routineProgress(name: "Daily Hydration", detail: "47 of 56 completed", symbol: "drop.fill", value: 0.84, color: JomadoTheme.cyan)
            Divider()
            routineProgress(name: "Evening Wind Down", detail: "6 of 14 completed", symbol: "moon.fill", value: 0.43, color: Color(jomadoHex: "7C5CFC"))
        }
        .jomadoCard()
    }

    private func insightMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private func routineProgress(name: String, detail: String, symbol: String, value: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            JomadoIconBadge(symbol: symbol, color: color, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                Text(detail)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
            }
            Spacer()
            Text("\(Int(value * 100))%")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.13))
                    Capsule().fill(color).frame(width: proxy.size.width * CGFloat(value))
                }
            }
            .frame(width: 82, height: 9)
        }
    }
}

private enum InsightPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case allTime

    var id: String { rawValue }
    var title: String {
        switch self {
        case .week: "This Week"
        case .month: "This Month"
        case .allTime: "All Time"
        }
    }
}

private struct InsightDay: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

#Preview {
    InsightsView()
}
