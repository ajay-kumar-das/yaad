import Foundation
import SwiftUI

struct ReminderExperienceView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var presentation: ReminderPresentation { model.presentation }
    private var content: ReminderContentItem { presentation.content }
    private var stageColor: Color { Color(jomadoHex: presentation.stage.accentHex) }

    private var backgroundColors: [Color] {
        switch presentation.stage {
        case .normal:
            [stageColor.opacity(0.34), Color(jomadoHex: "DFF8FF"), .white]
        case .lightOverdue:
            [Color(jomadoHex: "FFE58A"), Color(jomadoHex: "FFF1B8"), Color(jomadoHex: "FFF9E4")]
        case .mediumOverdue:
            [Color(jomadoHex: "FF9A3D"), Color(jomadoHex: "FFC078"), Color(jomadoHex: "FFF0DC")]
        case .redZone:
            [Color(jomadoHex: "FF4D5A"), Color(jomadoHex: "E3293F"), Color(jomadoHex: "A9122A")]
        case .completed:
            [Color(jomadoHex: "79D99A"), Color(jomadoHex: "DDF7E5"), .white]
        }
    }

    private var strongUrgency: Bool {
        presentation.stage == .mediumOverdue || presentation.stage == .redZone
    }

    var body: some View {
        ZStack {
            reminderBackground

            ScrollView {
                VStack(spacing: 0) {
                    topBar
                    statusPill
                        .padding(.top, 14)

                    AnimatedMomoView(
                        mascotID: model.activeMascotID,
                        expression: content.mascot.expression,
                        cue: content.mascot.animationCue,
                        accessibilityLabel: content.mascot.accessibilityLabel
                    )
                    .frame(width: 250, height: 250)
                    .padding(.top, 4)

                    reminderCopy
                        .padding(.top, 4)

                    if model.occurrence.status == .completed {
                        completionControls
                    } else {
                        actionControls
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 34)
            }

            if model.occurrence.status == .completed && !reduceMotion {
                ConfettiBurst()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .preferredColorScheme(.light)
        .task {
            while !Task.isCancelled, !model.occurrence.status.isTerminal {
                await model.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private var reminderBackground: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.45))
                .frame(width: 250)
                .blur(radius: 1)
                .offset(x: 130, y: -290)

            Circle()
                .fill(stageColor.opacity(0.14))
                .frame(width: 180)
                .offset(x: -145, y: 275)
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: model.occurrence.routineType.symbolName)
                    .foregroundStyle(presentation.stage == .redZone ? .white : stageColor)
                Text("JOMADO")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(presentation.stage == .redZone ? .white : JomadoTheme.navy)
            }

            Spacer()

            Button {
                model.closeReminder()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.85), in: Circle())
            }
            .foregroundStyle(presentation.stage == .redZone ? .white : JomadoTheme.navy)
            .accessibilityLabel("Close reminder without completing")
        }
        .padding(.top, 8)
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stageColor)
                .frame(width: 9, height: 9)
            Text(presentation.statusText)
                .contentTransition(.numericText())
        }
        .font(.system(.subheadline, design: .rounded, weight: .bold))
        .foregroundStyle(JomadoTheme.navy)
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
        .background(.white.opacity(0.9), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reminder status, \(presentation.statusText)")
    }

    private var reminderCopy: some View {
        VStack(spacing: 12) {
            Text(content.variants.inApp.eyebrow)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .tracking(1.3)
                .foregroundStyle(stageColor)

            Text(content.variants.inApp.headline)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(JomadoTheme.navy)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)

            Text(content.variants.inApp.body)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if let tip = content.variants.inApp.tip {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(stageColor)
                    Text(tip)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.navy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, strongUrgency ? 16 : 0)
        .padding(.vertical, strongUrgency ? 16 : 0)
        .background(
            strongUrgency ? Color.white.opacity(0.90) : Color.clear,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var actionControls: some View {
        VStack(spacing: 12) {
            if let lockText = model.reminderActionLockText {
                Label(lockText, systemImage: "lock.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(JomadoTheme.navy)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                Task { await model.complete() }
            } label: {
                Label(model.occurrence.completionLabel, systemImage: "checkmark.circle.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: presentation.stage == .normal
                        ? [JomadoTheme.cyan, JomadoTheme.blue]
                        : [stageColor, stageColor.opacity(0.78)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: JomadoTheme.cyan.opacity(0.28), radius: 14, y: 8)
            .disabled(!model.reminderActionsAvailable)
            .opacity(model.reminderActionsAvailable ? 1 : 0.45)

            if let snoozeMinutes = model.activeSnoozeMinutes {
                Button {
                    Task { await model.remindLater() }
                } label: {
                    Label(
                        "Remind me in \(snoozeMinutes) min",
                        systemImage: "clock.arrow.circlepath"
                    )
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                }
                .buttonStyle(.plain)
                .foregroundStyle(JomadoTheme.navy)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .disabled(!model.reminderActionsAvailable)
                .opacity(model.reminderActionsAvailable ? 1 : 0.45)
            } else if let message = model.snoozeUnavailableMessage {
                Label(message, systemImage: "clock.badge.xmark")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button("Skip this one") {
                Task { await model.skip() }
            }
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(JomadoTheme.secondaryText)
            .frame(minHeight: 44)
            .disabled(!model.reminderActionsAvailable)
            .opacity(model.reminderActionsAvailable ? 1 : 0.45)

            Text("Closing, dismissing, or snoozing never counts as completion.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(.top, 24)
    }

    private var completionControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                completionMetric(value: "1", label: "done today", symbol: "checkmark")
                completionMetric(value: "1 day", label: "current streak", symbol: "flame.fill")
            }

            Button("Done") {
                model.closeReminder()
                dismiss()
            }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(JomadoTheme.success, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.top, 24)
    }

    private func completionMetric(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(JomadoTheme.success)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ConfettiBurst: View {
    @State private var expanded = false

    private let colors: [Color] = [
        JomadoTheme.cyan,
        JomadoTheme.success,
        Color(jomadoHex: "F7C948"),
        Color(jomadoHex: "FF8A2B"),
        Color(jomadoHex: "8F68E8")
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<18, id: \.self) { index in
                    ConfettiParticle(
                        index: index,
                        color: colors[index % colors.count],
                        expanded: expanded,
                        containerSize: proxy.size
                    )
                }
            }
            .position(x: proxy.size.width / 2, y: proxy.size.height * 0.42)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.45)) {
                expanded = true
            }
        }
    }
}

private struct ConfettiParticle: View {
    let index: Int
    let color: Color
    let expanded: Bool
    let containerSize: CGSize

    private var rotation: Angle {
        .degrees(expanded ? Double(index * 47) : 0)
    }

    private var xOffset: CGFloat {
        guard expanded else { return 0 }
        return CGFloat(cos(Double(index) * 1.7)) * containerSize.width * 0.48
    }

    private var yOffset: CGFloat {
        guard expanded else { return -10 }
        return CGFloat(sin(Double(index) * 1.3)) * containerSize.height * 0.42
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 7, height: 12)
            .rotationEffect(rotation)
            .offset(x: xOffset, y: yOffset)
            .opacity(expanded ? 0 : 1)
    }
}

#Preview {
    ReminderExperienceView()
        .environmentObject(JomadoAppModel())
}
