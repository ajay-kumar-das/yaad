import Foundation
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: JomadoAppModel
    @Environment(\.scenePhase) private var scenePhase
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
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await model.drainExternalEvents()
                await model.reconcileSchedules()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            Task { await model.reconcileSchedules() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            Task { await model.reconcileSchedules() }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $model.selectedTab) {
            TodayView()
                .tag(JomadoTab.today)
                .tabItem { Label("Today", systemImage: "house.fill") }

            RoutinesView()
                .tag(JomadoTab.routines)
                .tabItem { Label("Routines", systemImage: "checkmark.circle") }

            InsightsView()
                .tag(JomadoTab.insights)
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            SettingsView()
                .tag(JomadoTab.settings)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(JomadoTheme.cyan)
    }
}
