import SwiftData
import SwiftUI

@main
struct JomadoApp: App {
    @UIApplicationDelegateAdaptor(JomadoAppDelegate.self) private var appDelegate
    @StateObject private var model = JomadoAppModel()

    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: RoutineEntity.self,
                ReminderOccurrenceEntity.self,
                ContentExposureEntity.self
            )
        } catch {
            fatalError("Unable to initialize Jomado local store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .task {
                    model.configure(modelContext: modelContainer.mainContext)
                    await model.bootstrap()
                }
                .onOpenURL { model.handle(url: $0) }
        }
        .modelContainer(modelContainer)
    }
}
