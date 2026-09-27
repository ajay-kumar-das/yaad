import SwiftUI

enum JomadoTheme {
    static let navy = Color(jomadoHex: "071D4A")
    static let cyan = Color(jomadoHex: "13BDEB")
    static let blue = Color(jomadoHex: "1597F4")
    static let sky = Color(jomadoHex: "DFF8FF")
    static let success = Color(jomadoHex: "34C759")
    static let secondaryText = Color(jomadoHex: "7284A4")

    static let pageGradient = LinearGradient(
        colors: [Color(jomadoHex: "CFF6FF"), .white, Color(jomadoHex: "EFFBFF")],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct JomadoCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: JomadoTheme.navy.opacity(0.08), radius: 18, y: 8)
    }
}

extension View {
    func jomadoCard() -> some View {
        modifier(JomadoCardModifier())
    }

    func jomadoPageBackground() -> some View {
        background(JomadoTheme.pageGradient.ignoresSafeArea())
    }
}

