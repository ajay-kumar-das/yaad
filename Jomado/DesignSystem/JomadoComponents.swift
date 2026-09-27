import SwiftUI

struct JomadoLandscapeBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(jomadoHex: "9EEBFF"),
                        Color(jomadoHex: "DFF8FF"),
                        .white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .fill(Color(jomadoHex: "FFF39A").opacity(0.92))
                    .frame(width: 72, height: 72)
                    .blur(radius: 2)
                    .position(x: proxy.size.width * 0.78, y: proxy.size.height * 0.2)

                cloud(width: 150)
                    .position(x: proxy.size.width * 0.16, y: proxy.size.height * 0.26)

                cloud(width: 120)
                    .position(x: proxy.size.width * 0.88, y: proxy.size.height * 0.34)

                Ellipse()
                    .fill(Color(jomadoHex: "8FD9B5").opacity(0.7))
                    .frame(width: proxy.size.width * 0.9, height: proxy.size.height * 0.32)
                    .rotationEffect(.degrees(-7))
                    .position(x: proxy.size.width * 0.12, y: proxy.size.height * 0.91)

                Ellipse()
                    .fill(Color(jomadoHex: "5BCF9C").opacity(0.5))
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.25)
                    .rotationEffect(.degrees(8))
                    .position(x: proxy.size.width * 0.84, y: proxy.size.height * 0.91)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private func cloud(width: CGFloat) -> some View {
        HStack(spacing: -18) {
            Circle().frame(width: width * 0.42, height: width * 0.42)
            Circle().frame(width: width * 0.58, height: width * 0.58)
            Circle().frame(width: width * 0.36, height: width * 0.36)
        }
        .foregroundStyle(.white.opacity(0.74))
        .blur(radius: 1)
    }
}

struct JomadoBrandWordmark: View {
    var body: some View {
        Text("Jomado")
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .foregroundStyle(JomadoTheme.navy)
            .accessibilityAddTraits(.isHeader)
    }
}

struct JomadoPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                LinearGradient(
                    colors: [Color(jomadoHex: "08C8DE"), JomadoTheme.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .shadow(color: JomadoTheme.cyan.opacity(0.28), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct JomadoIconBadge: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 48

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.13), in: Circle())
    }
}

struct JomadoProgressRing: View {
    let progress: Double
    let color: Color
    let label: String
    var size: CGFloat = 94

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.13), lineWidth: 12)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(colors: [color, JomadoTheme.cyan], center: .center),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(JomadoTheme.navy)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Progress, \(label)")
    }
}

struct JomadoSpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(JomadoTheme.navy)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: JomadoTheme.navy.opacity(0.08), radius: 8, y: 4)
    }
}

struct JomadoStepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(1...total, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? JomadoTheme.cyan : Color.white.opacity(0.75))
                    .frame(width: step == current ? 28 : 10, height: 10)
            }
        }
        .accessibilityLabel("Step \(current) of \(total)")
    }
}
