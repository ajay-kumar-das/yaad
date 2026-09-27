import SwiftUI

public struct MomoArtwork: View {
    private let mascot: CompanionMascot
    private let expression: MascotExpression
    private let accessibilityLabel: String

    public init(
        mascotID: String = CompanionMascot.momo.rawValue,
        expression: MascotExpression,
        accessibilityLabel: String? = nil
    ) {
        self.mascot = CompanionMascot(rawValue: mascotID) ?? .momo
        self.expression = expression
        self.accessibilityLabel = accessibilityLabel ?? "\(self.mascot.displayName). \(expression.accessibilityDescription)"
    }

    private var bodyStyle: CompanionBodyShape.Style {
        switch mascot {
        case .momo: .droplet
        case .momoMint: .orb
        case .momoViolet: .bean
        }
    }

    private var palette: (top: Color, middle: Color, bottom: Color, limb: Color, shadow: Color) {
        switch mascot {
        case .momo:
            (Color(jomadoHex: "42DBFF"), Color(jomadoHex: "13BDEB"), Color(jomadoHex: "0875D8"), Color(jomadoHex: "0C8FE9"), Color(jomadoHex: "1597F4"))
        case .momoMint:
            (Color(jomadoHex: "78F0D4"), Color(jomadoHex: "2BC9C3"), Color(jomadoHex: "159A91"), Color(jomadoHex: "198F88"), Color(jomadoHex: "2BC9C3"))
        case .momoViolet:
            (Color(jomadoHex: "C5AEFF"), Color(jomadoHex: "8F68E8"), Color(jomadoHex: "6556D8"), Color(jomadoHex: "6D57C9"), Color(jomadoHex: "8F68E8"))
        }
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                arm(size: size, leading: true)
                arm(size: size, leading: false)
                foot(size: size, leading: true)
                foot(size: size, leading: false)

                CompanionBodyShape(style: bodyStyle)
                    .fill(
                        LinearGradient(
                            colors: [palette.top, palette.middle, palette.bottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        CompanionBodyShape(style: bodyStyle)
                            .stroke(.white.opacity(0.42), lineWidth: max(1, size * 0.012))
                    }
                    .frame(width: size * 0.66, height: size * 0.78)
                    .position(x: size * 0.5, y: size * 0.47)
                    .shadow(color: palette.shadow.opacity(0.28), radius: size * 0.055, y: size * 0.035)

                Circle()
                    .fill(.white.opacity(0.78))
                    .frame(width: size * 0.085, height: size * 0.12)
                    .rotationEffect(.degrees(28))
                    .position(x: size * 0.41, y: size * 0.235)

                face(size: size)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func arm(size: CGFloat, leading: Bool) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [palette.top, palette.bottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.13, height: size * 0.3)
            .rotationEffect(.degrees(leading ? 48 : -48))
            .position(x: size * (leading ? 0.225 : 0.775), y: size * 0.555)
    }

    private func foot(size: CGFloat, leading: Bool) -> some View {
        Capsule()
            .fill(palette.limb)
            .frame(width: size * 0.18, height: size * 0.12)
            .rotationEffect(.degrees(leading ? -12 : 12))
            .position(x: size * (leading ? 0.405 : 0.595), y: size * 0.845)
    }

    @ViewBuilder
    private func face(size: CGFloat) -> some View {
        let navy = Color(jomadoHex: "071D4A")
        let happyEyes = expression == .hello || expression == .proud || expression == .celebrating || expression == .sleepy
        let wink = expression == .cheeky
        let worried = expression == .concerned || expression == .urgent || expression == .dramatic
        let pout = expression == .pouty

        Group {
            eye(size: size, closed: happyEyes || wink)
                .position(x: size * 0.425, y: size * 0.49)

            eye(size: size, closed: happyEyes)
                .position(x: size * 0.575, y: size * 0.49)

            if worried {
                Capsule()
                    .fill(navy)
                    .frame(width: size * 0.095, height: size * 0.018)
                    .rotationEffect(.degrees(-12))
                    .position(x: size * 0.42, y: size * 0.43)

                Capsule()
                    .fill(navy)
                    .frame(width: size * 0.095, height: size * 0.018)
                    .rotationEffect(.degrees(12))
                    .position(x: size * 0.58, y: size * 0.43)
            }

            Circle()
                .fill(Color(jomadoHex: "FF91AD").opacity(0.88))
                .frame(width: size * 0.09, height: size * 0.055)
                .position(x: size * 0.35, y: size * 0.61)

            Circle()
                .fill(Color(jomadoHex: "FF91AD").opacity(0.88))
                .frame(width: size * 0.09, height: size * 0.055)
                .position(x: size * 0.65, y: size * 0.61)

            if pout {
                Capsule()
                    .fill(navy)
                    .frame(width: size * 0.075, height: size * 0.022)
                    .position(x: size * 0.5, y: size * 0.61)
            } else {
                MouthShape(isSmall: expression == .focused || expression == .waiting)
                    .fill(navy)
                    .frame(
                        width: size * (worried ? 0.115 : 0.15),
                        height: size * (worried ? 0.105 : 0.13)
                    )
                    .overlay(alignment: .bottom) {
                        if !worried && expression != .focused && expression != .waiting {
                            Ellipse()
                                .fill(Color(jomadoHex: "FF5A76"))
                                .frame(width: size * 0.075, height: size * 0.036)
                                .padding(.bottom, size * 0.012)
                        }
                    }
                    .position(x: size * 0.5, y: size * 0.605)
            }
        }
    }

    private func eye(size: CGFloat, closed: Bool) -> some View {
        Capsule()
            .fill(Color(jomadoHex: "071D4A"))
            .frame(
                width: size * (closed ? 0.085 : 0.047),
                height: size * (closed ? 0.022 : 0.075)
            )
            .rotationEffect(.degrees(closed ? -4 : 0))
    }
}

private struct CompanionBodyShape: Shape {
    enum Style { case droplet, orb, bean }
    let style: Style

    func path(in rect: CGRect) -> Path {
        switch style {
        case .droplet:
            return DropletShape().path(in: rect)
        case .orb:
            return Path(ellipseIn: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.08))
        case .bean:
            return RoundedRectangle(cornerRadius: rect.width * 0.28, style: .continuous)
                .path(in: rect.insetBy(dx: rect.width * 0.025, dy: rect.height * 0.04))
        }
    }
}

private struct DropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX + rect.width * 0.04, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.height * 0.57),
            control1: CGPoint(x: rect.width * 0.78, y: rect.height * 0.16),
            control2: CGPoint(x: rect.maxX, y: rect.height * 0.34)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.height * 0.85),
            control2: CGPoint(x: rect.width * 0.75, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.height * 0.57),
            control1: CGPoint(x: rect.width * 0.25, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.height * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.04, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.height * 0.32),
            control2: CGPoint(x: rect.width * 0.33, y: rect.height * 0.17)
        )
        path.closeSubpath()
        return path
    }
}

private struct MouthShape: Shape {
    let isSmall: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.2))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.height * 0.2),
            control1: CGPoint(x: rect.width * 0.27, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.73, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.height * 0.2),
            control1: CGPoint(x: rect.width * (isSmall ? 0.74 : 0.82), y: rect.maxY),
            control2: CGPoint(x: rect.width * (isSmall ? 0.26 : 0.18), y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}
