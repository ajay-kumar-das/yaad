import SwiftUI

struct RoutinesView: View {
    @State private var filter: RoutineFilter = .all
    @State private var isAddingRoutine = false
    @State private var routines = RoutineListItem.samples

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 16) {
                        Picker("Routine filter", selection: $filter) {
                            ForEach(RoutineFilter.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Filter routines")

                        LazyVStack(spacing: 12) {
                            ForEach($routines) { $routine in
                                if filter.includes(routine) {
                                    routineCard($routine)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .jomadoPageBackground()
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isAddingRoutine) {
                AddRoutineFlowView { routineType in
                    addRoutine(routineType)
                }
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            JomadoLandscapeBackground()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    JomadoBrandWordmark()
                    Text("Your\nRoutines")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(JomadoTheme.navy)
                    Text("Small habits. A happier,\nhealthier you.")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(JomadoTheme.secondaryText)
                }

                Spacer()

                Button {
                    isAddingRoutine = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(JomadoTheme.cyan, in: Circle())
                        .shadow(color: JomadoTheme.cyan.opacity(0.3), radius: 10, y: 5)
                }
                .accessibilityLabel("Add routine")
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            AnimatedMomoView(
                expression: .hello,
                cue: .gentleBounce,
                accessibilityLabel: "Momo cheers beside your routines"
            )
            .frame(width: 158, height: 158)
            .offset(x: 72, y: 86)
        }
        .frame(height: 278)
    }

    private func routineCard(_ routine: Binding<RoutineListItem>) -> some View {
        let type = routine.wrappedValue.type
        let accent = Color(jomadoHex: type.accentHex)

        return HStack(spacing: 13) {
            JomadoIconBadge(symbol: type.symbolName, color: accent, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(routine.wrappedValue.name)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(JomadoTheme.navy)
                Text(routine.wrappedValue.subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(JomadoTheme.secondaryText)
                    .lineLimit(1)
                Label(routine.wrappedValue.schedule, systemImage: "clock")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(JomadoTheme.navy.opacity(0.8))
            }

            Spacer(minLength: 4)

            Toggle("Enabled", isOn: routine.isEnabled)
                .labelsHidden()
                .tint(JomadoTheme.cyan)

            Image(systemName: "chevron.right")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(JomadoTheme.secondaryText)
        }
        .padding(15)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: JomadoTheme.navy.opacity(0.06), radius: 12, y: 6)
    }

    private func addRoutine(_ type: RoutineType) {
        guard !routines.contains(where: { $0.type == type }) else { return }
        routines.append(
            RoutineListItem(
                type: type,
                name: type.displayName,
                subtitle: "A new small habit to build.",
                schedule: "8:00 AM  •  Daily",
                isEnabled: true
            )
        )
    }
}

private enum RoutineFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case paused

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func includes(_ routine: RoutineListItem) -> Bool {
        return switch self {
        case .all: true
        case .active: routine.isEnabled
        case .paused: !routine.isEnabled
        }
    }
}

private struct RoutineListItem: Identifiable {
    let id = UUID()
    let type: RoutineType
    let name: String
    let subtitle: String
    let schedule: String
    var isEnabled: Bool

    static let samples: [RoutineListItem] = [
        RoutineListItem(type: .hydration, name: "Hydration", subtitle: "Drink water and feel your best.", schedule: "8:00 AM–10:00 PM  •  Every 60 min", isEnabled: true),
        RoutineListItem(type: .exercise, name: "Exercise", subtitle: "Get moving for a stronger you.", schedule: "7:00 AM  •  Daily", isEnabled: true),
        RoutineListItem(type: .eyeCare, name: "Eye Break", subtitle: "Give your eyes a rest.", schedule: "9:00 AM–6:00 PM  •  Every 60 min", isEnabled: true),
        RoutineListItem(type: .stretching, name: "Stretching", subtitle: "Loosen up and stay flexible.", schedule: "9:00 AM  •  Daily", isEnabled: true),
        RoutineListItem(type: .breathing, name: "Breathing", subtitle: "Take a moment to reset.", schedule: "12:00 PM  •  Daily", isEnabled: false),
        RoutineListItem(type: .meditation, name: "Meditation", subtitle: "Find calm in your day.", schedule: "8:00 PM  •  Daily", isEnabled: true),
        RoutineListItem(type: .sleep, name: "Sleep", subtitle: "Rest well for a brighter tomorrow.", schedule: "10:00 PM  •  Daily", isEnabled: false)
    ]
}

#Preview {
    RoutinesView()
}
