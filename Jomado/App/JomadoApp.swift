import SwiftUI

@main
struct JomadoApp: App {
    @UIApplicationDelegateAdaptor(JomadoAppDelegate.self) private var appDelegate
    @StateObject private var model = JomadoAppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .task { await model.bootstrap() }
                .onOpenURL { model.handle(url: $0) }
        }
    }
}

