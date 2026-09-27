import SwiftUI

struct RoutinesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(RoutineTemplate.catalog.filter { $0.type != .custom }) { template in
                        HStack(spacing: 14) {
                            Image(systemName: template.symbolName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color(jomadoHex: template.accentHex))
                                .frame(width: 50, height: 50)
                                .background(
                                    Color(jomadoHex: template.accentHex).opacity(0.12),
                                    in: Circle()
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(template.displayName)
                                    .font(.system(.headline, design: .rounded, weight: .heavy))
                                    .foregroundStyle(JomadoTheme.navy)
                                Text("Ready for a schedule")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(JomadoTheme.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(JomadoTheme.secondaryText)
                        }
                        .jomadoCard()
                    }
                }
                .padding(18)
            }
            .jomadoPageBackground()
            .navigationTitle("Your Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) { Image(systemName: "plus") }
                }
            }
        }
    }
}

