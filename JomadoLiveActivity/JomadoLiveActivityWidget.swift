import ActivityKit
import SwiftUI
import WidgetKit

struct JomadoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JomadoActivityAttributes.self) { context in
            JomadoLockScreenActivityView(context: context)
                .activityBackgroundTint(.white)
                .activitySystemActionForegroundColor(LivePalette.navy)
                .widgetURL(deepLink(for: context.attributes.occurrenceID))
        } dynamicIsland: { context in
            let stage = effectiveStage(for: context)
            let accent = Color(jomadoHex: stage.accentHex)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveMomoArtwork(mascotID: context.attributes.mascotID, expression: context.state.expression, size: 46)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.routineName)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .lineLimit(1)
                        Text(context.state.message)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    LiveStatusText(
                        dueDate: context.state.dueDate,
                        isCompleted: context.state.isCompleted,
                        width: 64
                    )
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(accent)
                        .contentTransition(.numericText())
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 7) {
                        UrgencyRail(stage: stage)
                        Label(
                            context.state.isCompleted ? "Completed" : "Open Jomado to respond",
                            systemImage: context.state.isCompleted ? "checkmark.circle.fill" : "arrow.up.forward.app"
                        )
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(context.state.isCompleted ? LivePalette.success : .secondary)
                    }
                }
            } compactLeading: {
                LiveMomoArtwork(mascotID: context.attributes.mascotID, expression: context.state.expression, size: 24)
                    .accessibilityHidden(true)
            } compactTrailing: {
                LiveStatusText(
                    dueDate: context.state.dueDate,
                    isCompleted: context.state.isCompleted,
                    width: 46
                )
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
            } minimal: {
                ZStack {
                    Circle()
                        .stroke(accent, lineWidth: 2)
                    LiveMomoArtwork(mascotID: context.attributes.mascotID, expression: context.state.expression, size: 18)
                }
                .frame(width: 24, height: 24)
                .accessibilityLabel("\(context.attributes.routineName), \(context.state.compactStatus)")
            }
            .widgetURL(deepLink(for: context.attributes.occurrenceID))
            .keylineTint(accent)
        }
    }

    private func effectiveStage(
        for context: ActivityViewContext<JomadoActivityAttributes>
    ) -> ReminderUrgencyStage {
        if context.isStale && context.state.stage == .normal {
            return .lightOverdue
        }
        return context.state.stage
    }

    private func deepLink(for occurrenceID: String) -> URL? {
        URL(string: "jomado://occurrence/\(occurrenceID)")
    }
}

private struct JomadoLockScreenActivityView: View {
    let context: ActivityViewContext<JomadoActivityAttributes>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var stage: ReminderUrgencyStage {
        if context.isStale && context.state.stage == .normal {
            return .lightOverdue
        }
        return context.state.stage
    }

    private var accent: Color { Color(jomadoHex: stage.accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Jomado", systemImage: context.attributes.routineType.symbolName)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(LivePalette.navy)

                Spacer()

                LiveStatusText(
                    dueDate: context.state.dueDate,
                    isCompleted: context.state.isCompleted,
                    width: 64
                )
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
            }

            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(context.state.headline)
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(LivePalette.navy)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .contentTransition(.interpolate)

                    Text(context.state.message)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(LivePalette.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                LiveMomoArtwork(mascotID: context.attributes.mascotID, expression: context.state.expression, size: 82)
            }

            UrgencyRail(stage: stage)

            HStack {
                Text(stage.label)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(accent)
                Spacer()
                Label(
                    context.state.isCompleted ? "Great job" : "Tap to respond",
                    systemImage: context.state.isCompleted ? "checkmark.circle.fill" : "arrow.up.forward.app"
                )
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(context.state.isCompleted ? LivePalette.success : LivePalette.secondaryText)
            }
        }
        .padding(16)
        .animation(
            reduceMotion || isLuminanceReduced ? nil : .easeInOut(duration: 0.6),
            value: stage
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Jomado, \(context.attributes.routineName), \(stage.label). \(context.state.message)"
        )
    }
}

private struct LiveStatusText: View {
    let dueDate: Date
    let isCompleted: Bool
    let width: CGFloat

    var body: some View {
        Group {
            if isCompleted {
                Text("Done")
            } else {
                Text(
                    timerInterval: dueDate...dueDate.addingTimeInterval(8 * 60 * 60),
                    countsDown: false,
                    showsHours: true
                )
                .monospacedDigit()
                .accessibilityLabel("Time since reminder was due")
            }
        }
        .frame(width: width, alignment: .trailing)
    }
}

private struct UrgencyRail: View {
    let stage: ReminderUrgencyStage

    private var filledCount: Int {
        switch stage {
        case .normal: 1
        case .lightOverdue: 2
        case .mediumOverdue: 3
        case .redZone, .completed: 4
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index < filledCount ? Color(jomadoHex: stage.accentHex) : Color.gray.opacity(0.18))
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Urgency stage, \(stage.label)")
    }
}

private struct LiveMomoArtwork: View {
    let mascotID: String
    let expression: MascotExpression
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        MomoArtwork(mascotID: mascotID, expression: expression)
            .frame(width: size, height: size)
            .id(expression)
            .transition(.scale.combined(with: .opacity))
            .animation(
                reduceMotion || isLuminanceReduced
                    ? nil
                    : .spring(response: 0.5, dampingFraction: 0.72),
                value: expression
            )
    }
}

private enum LivePalette {
    static let navy = Color(jomadoHex: "071D4A")
    static let secondaryText = Color(jomadoHex: "7284A4")
    static let success = Color(jomadoHex: "34C759")
}
