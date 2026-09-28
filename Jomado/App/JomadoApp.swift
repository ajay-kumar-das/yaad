import Foundation
import SwiftData
import SwiftUI

@main
struct JomadoApp: App {
    @UIApplicationDelegateAdaptor(JomadoAppDelegate.self) private var appDelegate
    @StateObject private var model = JomadoAppModel()

    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            RoutineEntity.self,
            ReminderOccurrenceEntity.self,
            ContentExposureEntity.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: Self.isRunningTests
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Unable to initialize Jomado local store: \(error)")
        }
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
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
