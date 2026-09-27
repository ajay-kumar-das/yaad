import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Text("67%")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(JomadoTheme.navy)
                        Text("completed this week")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(JomadoTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .jomadoCard()

                    HStack(spacing: 12) {
                        metric(value: "47", label: "Completed", color: JomadoTheme.success)
                        metric(value: "12", label: "Open", color: JomadoTheme.blue)
                        metric(value: "6", label: "Skipped", color: Color(jomadoHex: "FFB020"))
                    }

                    Text("Only explicit completion actions count toward this progress.")
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .jomadoCard()
                }
                .padding(18)
            }
            .jomadoPageBackground()
            .navigationTitle("Your Progress")
        }
    }

    private func metric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

