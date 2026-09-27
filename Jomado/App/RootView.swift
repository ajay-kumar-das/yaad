import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: JomadoAppModel

    var body: some View {
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
        .fullScreenCover(isPresented: $model.isReminderPresented) {
            ReminderExperienceView()
                .environmentObject(model)
        }
    }
}
