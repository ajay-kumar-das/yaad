import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

@MainActor
final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        preferredContentSize = CGSize(width: 0, height: 238)
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        let info = content.userInfo

        let routineType = (info["routineType"] as? String)
            .flatMap(RoutineType.init(rawValue:)) ?? .generic
        let requestedMascot = info["mascotID"] as? String
        let mascot = CompanionMascot(rawValue: requestedMascot ?? "")
            ?? CompanionMascot.preferred(for: routineType)

        install(
            rootView: AnyView(
                NotificationMascotView(
                    title: content.title,
                    message: content.body,
                    routineType: routineType,
                    mascot: mascot
                )
            )
        )
    }

    private func install(rootView: AnyView) {
        if let hostingController {
            hostingController.rootView = rootView
            return
        }

        let hosting = UIHostingController(rootView: rootView)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }
}

private struct NotificationMascotView: View {
    let title: String
    let message: String
    let routineType: RoutineType
    let mascot: CompanionMascot

    private var expression: MascotExpression {
        switch mascot {
        case .momo: .hello
        case .momoMint: .hopeful
        case .momoViolet: .focused
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(jomadoHex: routineType.accentHex).opacity(0.20),
                    .white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                MomoArtwork(
                    mascotID: mascot.rawValue,
                    expression: expression,
                    accessibilityLabel: "\(mascot.displayName) for \(routineType.displayName)"
                )
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 7) {
                    Label(routineType.displayName, systemImage: routineType.symbolName)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(Color(jomadoHex: routineType.accentHex))

                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Color(jomadoHex: "071D4A"))
                        .lineLimit(2)

                    Text(message)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(jomadoHex: "566A8E"))
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
