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
            let stage = context.state.stage
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
                        width: 88,
                        showsLateLabel: true
                    )
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(accent)
                        .contentTransition(.numericText())
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 7) {
                        LiveUrgencyRail(
                            dueDate: context.state.dueDate,
                            isCompleted: context.state.isCompleted
                        )
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
                    width: 46,
                    showsLateLabel: false
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

    private func deepLink(for occurrenceID: String) -> URL? {
        URL(string: "jomado://occurrence/\(occurrenceID)")
    }
}

private struct JomadoLockScreenActivityView: View {
    let context: ActivityViewContext<JomadoActivityAttributes>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var stage: ReminderUrgencyStage {
        context.state.stage
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
                    width: 92,
                    showsLateLabel: true
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

            LiveUrgencyRail(
                dueDate: context.state.dueDate,
                isCompleted: context.state.isCompleted
            )

            HStack {
                Text(context.state.isCompleted ? "Completed" : "Delay increases until 20 min")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(context.state.isCompleted ? LivePalette.success : accent)
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
            "Jomado, \(context.attributes.routineName). \(context.state.message). Delay timer is shown on screen."
        )
    }
}

private struct LiveStatusText: View {
    let dueDate: Date
    let isCompleted: Bool
    let width: CGFloat
    let showsLateLabel: Bool

    var body: some View {
        Group {
            if isCompleted {
                Text("Done")
            } else {
                HStack(spacing: 3) {
                    Text(dueDate, style: .timer)
                        .monospacedDigit()
                    if showsLateLabel {
                        Text("late")
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Time since reminder was due")
            }
        }
        .frame(width: width, alignment: .trailing)
    }
}

private struct LiveUrgencyRail: View {
    let dueDate: Date
    let isCompleted: Bool

    private var escalationEnd: Date {
        dueDate.addingTimeInterval(20 * 60)
    }

    var body: some View {
        VStack(spacing: 5) {
            LinearGradient(
                colors: [
                    LivePalette.cyan,
                    LivePalette.success,
                    LivePalette.yellow,
                    LivePalette.orange,
                    LivePalette.red
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 6)
            .clipShape(Capsule())

            if !isCompleted {
                ProgressView(
                    timerInterval: dueDate...escalationEnd,
                    countsDown: false
                )
                .labelsHidden()
                .tint(LivePalette.navy.opacity(0.72))
                .frame(height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            isCompleted
                ? "Completed"
                : "Delay urgency progresses from blue through green, yellow, orange, and red over twenty minutes"
        )
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
    static let cyan = Color(jomadoHex: "13BDEB")
    static let success = Color(jomadoHex: "34C759")
    static let yellow = Color(jomadoHex: "F7C948")
    static let orange = Color(jomadoHex: "FF8A2B")
    static let red = Color(jomadoHex: "FF4D5A")
}
