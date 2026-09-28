import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

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

        let view = NotificationMascotView(
            title: content.title,
            body: content.body,
            routineType: routineType,
            mascot: mascot
        )

        install(rootView: AnyView(view))
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
    let body: String
    let routineType: RoutineType
    let mascot: CompanionMascot

    private var expression: MascotExpression {
        switch mascot {
        case .momo: .hello
        case .momoMint: .hopeful
        case .momoViolet: .focused
        }
    }

    var bodyView: some View {
        EmptyView()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(jomadoHex: routineType.accentHex).opacity(0.20),
                    Color.white
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
                .frame(width: 112, height: 112)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Image(systemName: routineType.symbolName)
                            .foregroundStyle(Color(jomadoHex: routineType.accentHex))
                        Text(routineType.displayName)
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(Color(jomadoHex: "7284A4"))
                    }

                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Color(jomadoHex: "071D4A"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(body)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(jomadoHex: "566A8E"))
                        .lineLimit(3)

                    Text(mascot.displayName)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(jomadoHex: routineType.accentHex))
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
