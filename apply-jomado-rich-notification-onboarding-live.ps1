$ErrorActionPreference = "Stop"

$ExpectedMain = "0840832a4025c290ac367b75bc9ecce4b59c9de1"
$RepoRoot = (Get-Location).Path
$BundleRoot = $PSScriptRoot
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Replace-Exact {
    param(
        [string]$Path,
        [string]$Old,
        [string]$New,
        [string]$AlreadyPresent
    )

    $FullPath = Join-Path $RepoRoot $Path
    $Text = [System.IO.File]::ReadAllText($FullPath)

    if ($AlreadyPresent -and $Text.Contains($AlreadyPresent)) {
        Write-Host "Already updated: $Path"
        return
    }

    $Count = ([regex]::Matches($Text, [regex]::Escape($Old))).Count
    if ($Count -ne 1) {
        throw "$Path : expected exactly 1 source match, found $Count"
    }

    $Text = $Text.Replace($Old, $New)
    [System.IO.File]::WriteAllText($FullPath, $Text, $Utf8)
    Write-Host "Updated: $Path"
}

function Copy-BundleFile {
    param([string]$RelativePath)

    $Source = Join-Path $BundleRoot ("files\" + $RelativePath)
    $Destination = Join-Path $RepoRoot $RelativePath
    $Parent = Split-Path $Destination -Parent

    if (!(Test-Path $Parent)) {
        New-Item -ItemType Directory -Force $Parent | Out-Null
    }

    Copy-Item $Source $Destination -Force
    Write-Host "Copied: $RelativePath"
}

git fetch origin | Out-Null
$OriginMain = (git rev-parse origin/main).Trim()

if ($OriginMain -ne $ExpectedMain) {
    throw "origin/main changed. Expected $ExpectedMain but found $OriginMain. Regenerate against latest main before applying."
}

# ------------------------------------------------------------------
# Onboarding: reset scroll position between steps.
# ------------------------------------------------------------------

$Path = "Jomado/Features/Onboarding/OnboardingFlowView.swift"

$Old = @'
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    Group {
                        switch step {
                        case 1: welcomeContent
                        case 2: profileContent
                        case 3: focusContent
                        case 4: permissionsContent
                        default: allSetContent
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    .padding(.horizontal, 18)
                    .padding(.top, step == 1 || step == 5 ? 20 : 12)
                    .padding(.bottom, 24)
                }
            }
'@

$New = @'
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 1)
                            .id("onboarding-top")

                        hero

                        Group {
                            switch step {
                            case 1: welcomeContent
                            case 2: profileContent
                            case 3: focusContent
                            case 4: permissionsContent
                            default: allSetContent
                            }
                        }
                        .id(step)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                        .padding(.horizontal, 18)
                        .padding(.top, step == 1 || step == 5 ? 20 : 12)
                        .padding(.bottom, 24)
                    }
                }
                .onChange(of: step) { _, _ in
                    DispatchQueue.main.async {
                        proxy.scrollTo("onboarding-top", anchor: .top)
                    }
                }
            }
'@

Replace-Exact $Path $Old $New 'ScrollViewReader { proxy in'

# Gender choices: 2 columns, no 3-column truncation.
$Old = @'
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(["Woman", "Man", "Non-binary"], id: \.self) { option in
                        choiceButton(title: option, symbol: "person.fill", selected: gender == option) {
                            gender = option
                        }
                    }
                }
                HStack(spacing: 8) {
                    choiceButton(title: "Self describe", symbol: "pencil", selected: gender == "Self describe") {
                        gender = "Self describe"
                    }
                    choiceButton(title: "Prefer not to say", symbol: "hand.raised.fill", selected: gender == "Prefer not to say") {
                        gender = "Prefer not to say"
                    }
                }
'@

$New = @'
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(
                        ["Woman", "Man", "Non-binary", "Self describe", "Prefer not to say"],
                        id: \.self
                    ) { option in
                        choiceButton(
                            title: option,
                            symbol: option == "Self describe"
                                ? "pencil"
                                : (option == "Prefer not to say" ? "hand.raised.fill" : "person.fill"),
                            selected: gender == option
                        ) {
                            gender = option
                        }
                    }
                }
'@

Replace-Exact $Path $Old $New '["Woman", "Man", "Non-binary", "Self describe", "Prefer not to say"]'

# Focus cards: icon/check on top; text gets full width and never hyphenates.
$Old = @'
                        HStack(spacing: 10) {
                            JomadoIconBadge(
                                symbol: routine.symbolName,
                                color: Color(jomadoHex: routine.accentHex),
                                size: 48
                            )
                            VStack(alignment: .leading, spacing: 3) {
                                Text(routine.displayName)
                                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                Text(focusSubtitle(for: routine))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(JomadoTheme.secondaryText)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: selectedRoutines.contains(routine) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedRoutines.contains(routine) ? JomadoTheme.cyan : Color.gray.opacity(0.35))
                        }
                        .foregroundStyle(JomadoTheme.navy)
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 84)
'@

$New = @'
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                JomadoIconBadge(
                                    symbol: routine.symbolName,
                                    color: Color(jomadoHex: routine.accentHex),
                                    size: 46
                                )

                                Spacer(minLength: 8)

                                Image(systemName: selectedRoutines.contains(routine) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedRoutines.contains(routine) ? JomadoTheme.cyan : Color.gray.opacity(0.35))
                            }

                            Text(routine.displayName)
                                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .lineLimit(1)
                                .minimumScaleFactor(0.74)
                                .allowsTightening(true)

                            Text(focusSubtitle(for: routine))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(JomadoTheme.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .foregroundStyle(JomadoTheme.navy)
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
'@

Replace-Exact $Path $Old $New 'minHeight: 112, alignment: .topLeading'

# Titles fit the device width without colliding with the status bar after reset.
$Old = @'
        .font(.system(size: 36, weight: .heavy, design: .rounded))
        .multilineTextAlignment(.center)
'@

$New = @'
        .font(.system(size: 34, weight: .heavy, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .allowsTightening(true)
        .multilineTextAlignment(.center)
'@

Replace-Exact $Path $Old $New '.font(.system(size: 34, weight: .heavy, design: .rounded))'

# Choice labels get priority so words like Man / Non-binary don't collapse.
$Old = @'
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(JomadoTheme.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .allowsTightening(true)
'@

$New = @'
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(JomadoTheme.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .allowsTightening(true)
                    .layoutPriority(1)
'@

Replace-Exact $Path $Old $New '.font(.system(size: 13, weight: .bold, design: .rounded))'

# ------------------------------------------------------------------
# Mascot metadata for notification attachment files.
# ------------------------------------------------------------------

$Path = "Shared/JomadoPresentationTypes.swift"

$Old = @'
    var suitableRoutineTypes: Set<RoutineType> {
'@

$New = @'
    var notificationAssetBaseName: String {
        switch self {
        case .momo: "momo-drop"
        case .momoMint: "momo-calm"
        case .momoViolet: "momo-move"
        }
    }

    var suitableRoutineTypes: Set<RoutineType> {
'@

Replace-Exact $Path $Old $New 'var notificationAssetBaseName: String'

# ------------------------------------------------------------------
# Notification payload + mascot attachment.
# ------------------------------------------------------------------

$Path = "Jomado/Services/NotificationScheduler.swift"

$Old = @'
        at deliveryDate: Date,
        isFollowUp: Bool = false,
        soundChoice: NotificationSoundChoice = .inherit
    ) async throws {
'@

$New = @'
        at deliveryDate: Date,
        isFollowUp: Bool = false,
        soundChoice: NotificationSoundChoice = .inherit,
        mascotID: String
    ) async throws {
'@

Replace-Exact $Path $Old $New 'mascotID: String'

$Old = @'
        notification.targetContentIdentifier = "occurrence.\(occurrence.id.uuidString)"
        notification.userInfo = [
            "occurrenceID": occurrence.id.uuidString,
            "routineID": occurrence.routineID.uuidString,
            "deepLink": "jomado://occurrence/\(occurrence.id.uuidString)"
        ]
'@

$New = @'
        notification.targetContentIdentifier = "occurrence.\(occurrence.id.uuidString)"
        notification.userInfo = [
            "occurrenceID": occurrence.id.uuidString,
            "routineID": occurrence.routineID.uuidString,
            "routineType": occurrence.routineType.rawValue,
            "routineName": occurrence.routineName,
            "mascotID": mascotID,
            "completionLabel": occurrence.completionLabel,
            "deepLink": "jomado://occurrence/\(occurrence.id.uuidString)"
        ]

        if let attachment = mascotAttachment(mascotID: mascotID) {
            notification.attachments = [attachment]
        }
'@

Replace-Exact $Path $Old $New '"mascotID": mascotID'

$Old = @'
    private func notificationSound(
        for choice: NotificationSoundChoice
    ) -> UNNotificationSound? {
'@

$New = @'
    private func mascotAttachment(mascotID: String) -> UNNotificationAttachment? {
        guard let mascot = CompanionMascot(rawValue: mascotID) else { return nil }

        let baseName = mascot.notificationAssetBaseName
        let sourceURL =
            Bundle.main.url(
                forResource: baseName,
                withExtension: "png",
                subdirectory: "Mascots"
            )
            ?? Bundle.main.url(
                forResource: baseName,
                withExtension: "png"
            )

        guard let sourceURL else { return nil }

        do {
            let fileManager = FileManager.default
            let supportDirectory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let notificationDirectory = supportDirectory
                .appendingPathComponent("NotificationMascots", isDirectory: true)

            try fileManager.createDirectory(
                at: notificationDirectory,
                withIntermediateDirectories: true
            )

            let destination = notificationDirectory
                .appendingPathComponent("\(baseName).png")

            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }

            try fileManager.copyItem(at: sourceURL, to: destination)

            return try UNNotificationAttachment(
                identifier: "mascot.\(mascot.rawValue)",
                url: destination,
                options: nil
            )
        } catch {
            #if DEBUG
            print("Unable to prepare mascot notification attachment: \(error)")
            #endif
            return nil
        }
    }

    private func notificationSound(
        for choice: NotificationSoundChoice
    ) -> UNNotificationSound? {
'@

Replace-Exact $Path $Old $New 'private func mascotAttachment(mascotID: String)'

# ------------------------------------------------------------------
# Coordinator: use one compatible mascot across notification + Live Activity.
# Also start the nearest activity immediately when it's within 5 minutes,
# while preserving scheduled activities for closed-app future delivery.
# ------------------------------------------------------------------

$Path = "Jomado/Services/RoutineSchedulingCoordinator.swift"

$Old = @'
                let domain = entity.domainOccurrence(for: item.routine)

                if liveActivityCoordinator.activitiesEnabled,
'@

$New = @'
                let domain = entity.domainOccurrence(for: item.routine)
                let mascotID = item.routine.mascotID(for: item.key)

                if liveActivityCoordinator.activitiesEnabled,
'@

Replace-Exact $Path $Old $New 'let mascotID = item.routine.mascotID(for: item.key)'

$Old = @'
                        do {
                            try liveActivityCoordinator.schedule(
                                occurrence: domain,
                                presentation: livePresentation,
                                mascotID: item.routine.mascotID(for: item.key)
                            )
                        } catch {
'@

$New = @'
                        do {
                            if item.date.timeIntervalSince(now) <= 5 * 60 {
                                try await liveActivityCoordinator.start(
                                    occurrence: domain,
                                    presentation: livePresentation,
                                    mascotID: mascotID
                                )
                            } else {
                                try liveActivityCoordinator.schedule(
                                    occurrence: domain,
                                    presentation: livePresentation,
                                    mascotID: mascotID
                                )
                            }
                        } catch {
'@

Replace-Exact $Path $Old $New 'item.date.timeIntervalSince(now) <= 5 * 60'

$Old = @'
                            at: item.date,
                            soundChoice: item.routine.notificationSound
                        )
'@

$New = @'
                            at: item.date,
                            soundChoice: item.routine.notificationSound,
                            mascotID: mascotID
                        )
'@

Replace-Exact $Path $Old $New 'soundChoice: item.routine.notificationSound,'

$Old = @'
                        at: followUpDate,
                        isFollowUp: true,
                        soundChoice: routine.notificationSound
                    )
'@

$New = @'
                        at: followUpDate,
                        isFollowUp: true,
                        soundChoice: routine.notificationSound,
                        mascotID: routine.mascotID(for: entity.occurrenceKey)
                    )
'@

Replace-Exact $Path $Old $New 'mascotID: routine.mascotID(for: entity.occurrenceKey)'

$Old = @'
                        at: followUp,
                        isFollowUp: true,
                        soundChoice: routine.notificationSound
                    )
'@

$New = @'
                        at: followUp,
                        isFollowUp: true,
                        soundChoice: routine.notificationSound,
                        mascotID: routine.mascotID(for: occurrenceEntity.occurrenceKey)
                    )
'@

Replace-Exact $Path $Old $New 'mascotID: routine.mascotID(for: occurrenceEntity.occurrenceKey)'

# ------------------------------------------------------------------
# XcodeGen: embed Notification Content Extension.
# ------------------------------------------------------------------

$Path = "project.yml"

$Old = @'
    dependencies:
      - target: JomadoLiveActivity
        embed: true

    settings:
'@

$New = @'
    dependencies:
      - target: JomadoLiveActivity
        embed: true
      - target: JomadoNotificationContent
        embed: true

    settings:
'@

Replace-Exact $Path $Old $New 'target: JomadoNotificationContent'

$Old = @'
  JomadoTests:
    type: bundle.unit-test
'@

$New = @'
  JomadoNotificationContent:
    type: app-extension
    platform: iOS
    deploymentTarget: "26.0"

    sources:
      - path: JomadoNotificationContent
      - path: Shared

    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ajaydas.jomado.notificationcontent
        INFOPLIST_FILE: Config/JomadoNotificationContent-Info.plist
        GENERATE_INFOPLIST_FILE: NO
        CODE_SIGN_STYLE: Automatic
        TARGETED_DEVICE_FAMILY: "1"
        APPLICATION_EXTENSION_API_ONLY: YES
        SKIP_INSTALL: YES

  JomadoTests:
    type: bundle.unit-test
'@

Replace-Exact $Path $Old $New '  JomadoNotificationContent:'

# ------------------------------------------------------------------
# Copy new extension, notification mascot assets and guaranteed RGB app icon.
# ------------------------------------------------------------------

Copy-BundleFile "JomadoNotificationContent\NotificationViewController.swift"
Copy-BundleFile "Config\JomadoNotificationContent-Info.plist"
Copy-BundleFile "Resources\Mascots\momo-drop.png"
Copy-BundleFile "Resources\Mascots\momo-calm.png"
Copy-BundleFile "Resources\Mascots\momo-move.png"
Copy-BundleFile "Resources\Assets.xcassets\AppIcon.appiconset\JomadoAppIcon.png"

Write-Host ""
Write-Host "Validation:"
git diff --check
git diff --stat
git status --short

Write-Host ""
Write-Host "Applied rich notification + onboarding + Live Activity integration."
Write-Host "Next: commit/push and let GitHub Actions compile the new extension target."
