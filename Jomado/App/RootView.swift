import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @AppStorage("jomado.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabs
                    .transition(.opacity)
            } else {
                OnboardingFlowView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $model.isReminderPresented) {
            ReminderExperienceView()
                .environmentObject(model)
        }
    }

    private var mainTabs: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "house.fill") }

            RoutinesView()
                .tabItem { Label("Routines", systemImage: "checkmark.circle") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(JomadoTheme.cyan)
    }
}
