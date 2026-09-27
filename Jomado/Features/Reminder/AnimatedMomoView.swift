import SwiftUI

struct AnimatedMomoView: View {
    let expression: MascotExpression
    let cue: MascotAnimationCue
    let accessibilityLabel: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        MomoArtwork(expression: expression, accessibilityLabel: accessibilityLabel)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(y: verticalOffset)
            .opacity(reduceMotion ? 1 : opacity)
            .animation(animation, value: isAnimating)
            .onAppear { restartAnimation() }
            .onChange(of: cue) { _, _ in restartAnimation() }
            .onChange(of: expression) { _, _ in restartAnimation() }
    }

    private var scale: CGFloat {
        guard !reduceMotion, isAnimating else { return 1 }
        return switch cue {
        case .gentleBounce, .celebrate: 1.055
        case .concernedPulse, .breathe: 1.03
        default: 1
        }
    }

    private var rotation: Double {
        guard !reduceMotion, isAnimating else { return 0 }
        return cue == .dramaticWobble ? 5 : 0
    }

    private var verticalOffset: CGFloat {
        guard !reduceMotion, isAnimating else { return 0 }
        return switch cue {
        case .idleFloat, .gentleBounce, .wave: -6
        case .celebrate: -12
        default: 0
        }
    }

    private var opacity: Double {
        cue == .breathe && isAnimating ? 0.88 : 1
    }

    private var animation: Animation {
        if reduceMotion {
            return .easeOut(duration: 0.2)
        }

        switch cue {
        case .none:
            return .default
        case .dramaticWobble:
            return .easeInOut(duration: 0.34).repeatCount(6, autoreverses: true)
        case .celebrate:
            return .spring(response: 0.3, dampingFraction: 0.52).repeatCount(5, autoreverses: true)
        case .breathe:
            return .easeInOut(duration: 2).repeatForever(autoreverses: true)
        case .idleFloat:
            return .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
        default:
            return .spring(response: 0.55, dampingFraction: 0.7).repeatForever(autoreverses: true)
        }
    }

    private func restartAnimation() {
        isAnimating = false
        Task { @MainActor in
            await Task.yield()
            isAnimating = true
        }
    }
}

