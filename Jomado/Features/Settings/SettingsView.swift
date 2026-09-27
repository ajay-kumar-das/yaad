import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: JomadoAppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Experience") {
                    Label("Reminder personality", systemImage: "face.smiling")
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                    Label("Accessibility", systemImage: "accessibility")
                }

                Section("Delivery") {
                    Label("Permissions", systemImage: "checkmark.shield.fill")
                    Label("Delivery health", systemImage: "waveform.path.ecg")
                }

                Section("Privacy") {
                    Label("Data stays on this device", systemImage: "lock.fill")
                    Label("Content packs", systemImage: "text.book.closed.fill")
                }

                #if DEBUG
                Section("Debug previews") {
                    Button("Send notification in 5 seconds") {
                        Task { await model.requestNotificationsAndSchedulePreview() }
                    }
                    Button("Start Live Activity") {
                        Task { await model.startLiveActivity() }
                    }
                    if let message = model.systemMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(JomadoTheme.secondaryText)
                    }
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .jomadoPageBackground()
            .navigationTitle("Settings")
        }
    }
}
